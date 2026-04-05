extends GutTest

func test_dictionary_creation():
	var dict = DictionaryService.new("res://data/words_en.txt", [])
	assert_not_null(dict, "Dictionary should be created")

func test_dictionary_is_valid_word_with_empty_string():
	var dict = DictionaryService.new("res://data/words_en.txt", [])
	assert_false(dict.is_valid_word(""), "Empty string should not be valid")

func test_dictionary_is_valid_word_with_whitespace():
	var dict = DictionaryService.new("res://data/words_en.txt", [])
	assert_false(dict.is_valid_word("   "), "Whitespace-only string should not be valid")

func test_dictionary_is_valid_word_with_numbers():
	var dict = DictionaryService.new("res://data/words_en.txt", [])
	assert_false(dict.is_valid_word("abc123"), "Words with numbers should not be valid")

func test_dictionary_is_valid_word_with_special_chars():
	var dict = DictionaryService.new("res://data/words_en.txt", [])
	assert_false(dict.is_valid_word("hello@world"), "Words with special chars should not be valid")

func test_dictionary_case_insensitive():
	var dict = DictionaryService.new("res://data/words_en.txt", [])
	# These should work the same regardless of case
	var result1 = dict.is_valid_word("HELLO")
	var result2 = dict.is_valid_word("hello")
	var result3 = dict.is_valid_word("Hello")
	assert_eq(result1, result2, "Case should not affect validity")
	assert_eq(result2, result3, "Case should not affect validity")

func test_dictionary_common_words():
	var dict = DictionaryService.new("res://data/words_en.txt", [])
	# Test some common words that should be in the dictionary
	assert_true(dict.is_valid_word("THE"), "THE should be valid")
	assert_true(dict.is_valid_word("AND"), "AND should be valid")
	assert_true(dict.is_valid_word("CAT"), "CAT should be valid")
	assert_true(dict.is_valid_word("DOG"), "DOG should be valid")

func test_dictionary_invalid_words():
	var dict = DictionaryService.new("res://data/words_en.txt", [])
	assert_false(dict.is_valid_word("XYZ"), "XYZ should not be valid")
	assert_false(dict.is_valid_word("QWERTYUIOP"), "Long invalid word should not be valid")

func test_dictionary_with_spanish():
	var spanish_dict = DictionaryService.new("res://data/words_es.txt", [241])  # Ñ is 241
	# This tests the extra_alpha parameter
	assert_not_null(spanish_dict, "Spanish dictionary should be created")
