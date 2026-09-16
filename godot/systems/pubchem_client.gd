class_name PubChemClient # Performs the browser build's optional PubChem formula verification without signals.
extends RefCounted # Uses a manually polled HTTPClient so the native project remains signal-free.

enum RequestState { IDLE, CONNECTING, REQUESTING, READING } # Tracks the low-level HTTP request lifecycle explicitly.

const HOST: String = "pubchem.ncbi.nlm.nih.gov" # Targets the same PubChem service as the browser implementation.
const TIMEOUT_MS: int = 4500 # Preserves the browser build's four-and-a-half-second verification timeout.

var _client: HTTPClient = HTTPClient.new() # Reuses one native HTTP client for formula checks.
var _state: RequestState = RequestState.IDLE # Stores current request lifecycle state.
var _formula: String = "" # Stores the formula currently being verified.
var _body: PackedByteArray = PackedByteArray() # Accumulates the JSON response body.
var _started_ms: int = 0 # Stores request start time for timeout enforcement.
var _cache: Dictionary = {} # Caches successful true/false online results just like the browser implementation.
var _result_ready: bool = false # Marks whether the caller can consume a completed result.
var _result_value: int = -1 # Stores one for exists, zero for absent, or negative one for unavailable.

func start_verify(formula: String) -> bool: # Starts a nonblocking PubChem lookup when no other lookup is active.
	if _state != RequestState.IDLE: # Prevents overlapping low-level requests.
		return false # Reports that the client is currently busy.
	_result_ready = false # Clears any previously consumed completion state.
	_formula = formula # Retains the requested ASCII formula.
	if _cache.has(formula): # Reuses a previous definitive PubChem answer immediately.
		_result_value = 1 if bool(_cache[formula]) else 0 # Converts the cached boolean to the tri-state integer representation.
		_result_ready = true # Makes the cached result available synchronously.
		return true # Reports that verification has been accepted.
	_client.close() # Clears any previous connection state before starting a fresh request.
	_body.clear() # Removes any previous response bytes.
	_started_ms = Time.get_ticks_msec() # Starts the browser-equivalent timeout window.
	var error: Error = _client.connect_to_host(HOST, 443, TLSOptions.client()) # Begins a certificate-verified HTTPS connection.
	if error != OK: # Handles immediate DNS/socket setup failure.
		_finish(-1) # Reports online verification as unavailable.
		return true # Reports that the request was accepted and completed as unavailable.
	_state = RequestState.CONNECTING # Begins polling connection progress.
	return true # Reports that the asynchronous verification was started.

func process() -> void: # Advances the low-level HTTP state machine once per native game frame.
	if _state == RequestState.IDLE: # Avoids unnecessary polling without an active request.
		return # Leaves completion state untouched.
	if Time.get_ticks_msec() - _started_ms > TIMEOUT_MS: # Enforces the browser implementation's timeout.
		_client.close() # Aborts the outstanding native connection.
		_finish(-1) # Reports online verification as unavailable rather than rejecting the chemistry.
		return # Stops processing the timed-out request.
	var poll_error: Error = _client.poll() # Advances DNS, TLS, request, and response IO without blocking the main thread.
	if poll_error != OK: # Handles a transport failure during any phase.
		_client.close() # Resets the low-level connection.
		_finish(-1) # Reports network verification as unavailable.
		return # Stops processing the failed request.
	match _state: # Processes the current lifecycle phase after polling.
		RequestState.CONNECTING: # Waits for DNS/TLS connection establishment.
			_process_connecting() # Sends the GET request once the host is connected.
		RequestState.REQUESTING: # Waits for response headers after sending the request.
			_process_requesting() # Validates the response code and enters body reading.
		RequestState.READING: # Streams the JSON response body without blocking.
			_process_reading() # Collects chunks and parses completion.
		_: # Ignores the idle state handled above.
			pass # Performs no additional work.

func has_result() -> bool: # Reports whether one verification result is waiting to be consumed.
	return _result_ready # Returns current completion availability.

func take_result() -> int: # Consumes the latest tri-state verification result.
	if not _result_ready: # Protects callers from reading an unfinished request.
		return -2 # Uses a distinct sentinel for no completed result.
	_result_ready = false # Marks the completion as consumed.
	return _result_value # Returns one, zero, or negative one for exists, absent, or unavailable.

func active_formula() -> String: # Returns the formula associated with the active or most recent request.
	return _formula # Exposes the retained formula for caller consistency checks.

func _process_connecting() -> void: # Sends the PubChem request after the secure connection is ready.
	var status: HTTPClient.Status = _client.get_status() # Reads current connection status after polling.
	if status == HTTPClient.STATUS_CONNECTED: # Detects a ready HTTPS connection.
		var path: String = "/rest/pug/compound/fastformula/%s/cids/JSON?MaxRecords=1" % _formula.uri_encode() # Recreates the browser PubChem endpoint exactly.
		var headers: PackedStringArray = PackedStringArray(["Accept: application/json", "User-Agent: Bohr-Builder-Godot/1.0"]) # Requests JSON using a descriptive native client identifier.
		var error: Error = _client.request(HTTPClient.METHOD_GET, path, headers) # Sends the formula lookup GET request.
		if error != OK: # Handles an immediate request-write failure.
			_client.close() # Resets transport state.
			_finish(-1) # Reports online verification as unavailable.
			return # Stops this request.
		_state = RequestState.REQUESTING # Begins waiting for response headers.
	elif status != HTTPClient.STATUS_RESOLVING and status != HTTPClient.STATUS_CONNECTING: # Detects terminal connection failure states.
		_client.close() # Resets the failed transport.
		_finish(-1) # Reports online verification as unavailable.

func _process_requesting() -> void: # Handles response headers and chooses whether to read a response body.
	var status: HTTPClient.Status = _client.get_status() # Reads current request status after polling.
	if status == HTTPClient.STATUS_REQUESTING: # Continues waiting while the server has not completed headers.
		return # Defers handling to a later frame.
	if not _client.has_response(): # Handles a completed request with no usable HTTP response.
		_client.close() # Resets transport state.
		_finish(-1) # Reports the lookup as unavailable.
		return # Stops processing this request.
	var response_code: int = _client.get_response_code() # Reads the PubChem HTTP response code.
	if response_code < 200 or response_code >= 300: # Matches browser behavior where any non-OK response means the formula was not found.
		_cache[_formula] = false # Caches the definitive absent response.
		_client.close() # Finishes the current HTTP exchange.
		_finish(0) # Reports that no PubChem compound was found.
		return # Stops before reading an error body.
	if status == HTTPClient.STATUS_BODY: # Detects a successful response with body bytes available.
		_state = RequestState.READING # Begins incremental JSON body reading.
		_process_reading() # Reads any bytes already buffered this frame.
	else: # Handles an unexpected successful response without a body.
		_cache[_formula] = false # Treats the missing identifier body as no compound result.
		_client.close() # Finishes the current exchange.
		_finish(0) # Reports no found compound.

func _process_reading() -> void: # Streams response bytes until the HTTP client leaves body-reading state.
	var chunk: PackedByteArray = _client.read_response_body_chunk() # Reads one currently available response chunk.
	if not chunk.is_empty(): # Appends only actual data bytes.
		_body.append_array(chunk) # Accumulates JSON without repeated string conversions.
	if _client.get_status() == HTTPClient.STATUS_BODY: # Detects that more response data may still arrive.
		return # Continues reading on a later frame.
	var text: String = _body.get_string_from_utf8() # Converts the completed JSON body to text.
	var parsed: Variant = JSON.parse_string(text) # Parses PubChem JSON into native Godot data.
	var exists: bool = false # Defaults malformed or incomplete data to no found compound.
	if parsed is Dictionary: # Validates the expected top-level JSON object.
		var root: Dictionary = parsed # Narrows the parsed variant to a dictionary.
		if root.has("IdentifierList") and root["IdentifierList"] is Dictionary: # Validates the expected PubChem identifier wrapper.
			var identifiers: Dictionary = root["IdentifierList"] # Reads the identifier payload.
			if identifiers.has("CID") and identifiers["CID"] is Array: # Validates the expected CID list.
				exists = not (identifiers["CID"] as Array).is_empty() # Matches the browser condition requiring at least one CID.
	_cache[_formula] = exists # Caches the definitive PubChem result.
	_client.close() # Closes the completed exchange for future reuse.
	_finish(1 if exists else 0) # Publishes the result to the freeplay system.

func _finish(value: int) -> void: # Stores one completed tri-state result and returns the client to idle.
	_result_value = value # Retains exists, absent, or unavailable status.
	_result_ready = true # Makes the result available to the caller.
	_state = RequestState.IDLE # Ends active polling until another formula is requested.
