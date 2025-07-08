## Theoretically works, but doesn't actually. Leaving as is for now.
class_name AESFileResource extends JSONFileResource

var aes := AESContext.new()

## Implement this in your own custom class to create a passkey for the type. Only one is necessary per project and should never change. Must be exactly 16 characters long.
func _get_passkey_16() -> StringName:
	return &"ABCDEFGHIJKLMNOP"


func _export_json_string() -> String:
	var key := _get_passkey_16().to_utf8_buffer()

	var data_string := super._export_json_string()
	data_string += " ".repeat(16 - (data_string.length() % 16))
	var data := data_string.to_utf8_buffer()

	aes.start(AESContext.MODE_ECB_ENCRYPT, key)
	var encrypted := aes.update(data)
	aes.finish()

	return encrypted.get_string_from_utf8()


func _import_json_string(text: String) -> void:
	var key := _get_passkey_16().to_utf8_buffer()
	var data := text.to_utf8_buffer()

	aes.start(AESContext.MODE_ECB_DECRYPT, key)
	var decrypted := aes.update(data)
	aes.finish()

	super._import_json_string(decrypted.get_string_from_utf8())
