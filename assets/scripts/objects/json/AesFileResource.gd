class_name AESFileResource extends JSONFileResource

const KEY_SIZE := 16
const IV_SIZE := 16

var aes := AESContext.new()
var crypto := Crypto.new()

func _get_path_ext() -> String:
	return ".dat"


var passkey : String :
	get: return _get_passkey()
func _get_passkey() -> String:
	return "PENNY_MY_BELOVED"


func _save_to_file(file: FileAccess, json: String) -> void:
	json += " ".repeat(KEY_SIZE - (json.length() % KEY_SIZE))

	var key := passkey.to_utf8_buffer()
	var iv := crypto.generate_random_bytes(IV_SIZE)
	var decrypted := json.to_utf8_buffer()

	aes.start(AESContext.MODE_CBC_ENCRYPT, key, iv)
	var encrypted := aes.update(decrypted)
	aes.finish()

	var result := PackedByteArray()
	result.append_array(iv)
	result.append_array(encrypted)

	file.store_buffer(result)

func _load_from_file(file: FileAccess) -> String:
	var data = file.get_buffer(file.get_length())

	var key := passkey.to_utf8_buffer()
	var iv := data.slice(0, IV_SIZE)
	var encrypted := data.slice(IV_SIZE)

	aes.start(AESContext.MODE_CBC_DECRYPT, key, iv)
	var decrypted := aes.update(encrypted)
	aes.finish()

	return decrypted.get_string_from_utf8()
