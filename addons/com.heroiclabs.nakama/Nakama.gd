@tool
extends Node

# The default host address of the server.
const DEFAULT_HOST : String = "127.0.0.1"

# The default port number of the server.
const DEFAULT_PORT : int = 7350

# The default timeout for the connections.
const DEFAULT_TIMEOUT = 3

# The default protocol scheme for the client connection.
const DEFAULT_CLIENT_SCHEME : String = "http"

# The default protocol scheme for the socket connection.
const DEFAULT_SOCKET_SCHEME : String = "ws"

# The default log level for the Nakama logger.
var DEFAULT_LOG_LEVEL = 5  # DEBUG level

var _http_adapter = null
var logger = null

var _NakamaLoggerClass = null
var _NakamaHTTPAdapterClass = null
var _NakamaSocketAdapterClass = null
var _NakamaClientClass = null
var _NakamaSocketClass = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_classes()
	if _NakamaLoggerClass:
		logger = _NakamaLoggerClass.new()

func _load_classes() -> void:
	_NakamaLoggerClass = load("res://addons/com.heroiclabs.nakama/utils/NakamaLogger.gd")
	_NakamaHTTPAdapterClass = load("res://addons/com.heroiclabs.nakama/client/NakamaHTTPAdapter.gd")
	_NakamaSocketAdapterClass = load("res://addons/com.heroiclabs.nakama/socket/NakamaSocketAdapter.gd")
	_NakamaClientClass = load("res://addons/com.heroiclabs.nakama/client/NakamaClient.gd")
	_NakamaSocketClass = load("res://addons/com.heroiclabs.nakama/socket/NakamaSocket.gd")

func get_client_adapter():
	if _http_adapter == null and _NakamaHTTPAdapterClass:
		_http_adapter = _NakamaHTTPAdapterClass.new()
		_http_adapter.logger = logger
		_http_adapter.name = "NakamaHTTPAdapter"
		add_child(_http_adapter)
	return _http_adapter

func create_socket_adapter():
	if not _NakamaSocketAdapterClass:
		return null
	var adapter = _NakamaSocketAdapterClass.new()
	adapter.name = "NakamaWebSocketAdapter"
	adapter.logger = logger
	add_child(adapter)
	return adapter

func create_client(p_server_key : String,
		p_host : String = DEFAULT_HOST,
		p_port : int = DEFAULT_PORT,
		p_scheme : String = DEFAULT_CLIENT_SCHEME,
		p_timeout : int = DEFAULT_TIMEOUT,
		p_log_level : int = 5):
	if not _NakamaClientClass:
		return null
	if logger:
		logger._level = p_log_level
	return _NakamaClientClass.new(get_client_adapter(), p_server_key, p_scheme, p_host, p_port, p_timeout)

func create_socket(p_host : String = DEFAULT_HOST,
		p_port : int = DEFAULT_PORT,
		p_scheme : String = DEFAULT_SOCKET_SCHEME):
	if not _NakamaSocketClass:
		return null
	return _NakamaSocketClass.new(create_socket_adapter(), p_host, p_port, p_scheme, true)

func create_socket_from(p_client):
	if not _NakamaSocketClass or not p_client:
		return null
	var scheme = "ws"
	if p_client.scheme == "https":
		scheme = "wss"
	return _NakamaSocketClass.new(create_socket_adapter(), p_client.host, p_client.port, scheme, true)
