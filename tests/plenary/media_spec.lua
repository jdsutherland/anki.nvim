local media = require("anki.media")
local Note = require("anki.classes.note")
local Field = require("anki.classes.field")
local EditorContext = require("anki.classes.editor_context")

describe("anki.media", function()
	describe("detect_media_type", function()
		it("detects image types", function()
			assert.are.equal("image", media.detect_media_type("photo.png"))
			assert.are.equal("image", media.detect_media_type("photo.jpg"))
			assert.are.equal("image", media.detect_media_type("photo.jpeg"))
			assert.are.equal("image", media.detect_media_type("photo.gif"))
			assert.are.equal("image", media.detect_media_type("photo.bmp"))
			assert.are.equal("image", media.detect_media_type("photo.svg"))
			assert.are.equal("image", media.detect_media_type("photo.webp"))
			assert.are.equal("image", media.detect_media_type("photo.avif"))
			assert.are.equal("image", media.detect_media_type("photo.tiff"))
		end)

		it("detects audio types", function()
			assert.are.equal("audio", media.detect_media_type("sound.mp3"))
			assert.are.equal("audio", media.detect_media_type("sound.wav"))
			assert.are.equal("audio", media.detect_media_type("sound.ogg"))
			assert.are.equal("audio", media.detect_media_type("sound.wma"))
			assert.are.equal("audio", media.detect_media_type("sound.flac"))
			assert.are.equal("audio", media.detect_media_type("sound.m4a"))
			assert.are.equal("audio", media.detect_media_type("sound.aac"))
			assert.are.equal("audio", media.detect_media_type("sound.opus"))
		end)

		it("detects video types", function()
			assert.are.equal("video", media.detect_media_type("video.mp4"))
			assert.are.equal("video", media.detect_media_type("video.mov"))
			assert.are.equal("video", media.detect_media_type("video.avi"))
			assert.are.equal("video", media.detect_media_type("video.mkv"))
			assert.are.equal("video", media.detect_media_type("video.webm"))
		end)

		it("is case-insensitive for extensions", function()
			assert.are.equal("image", media.detect_media_type("photo.PNG"))
			assert.are.equal("audio", media.detect_media_type("sound.MP3"))
			assert.are.equal("video", media.detect_media_type("video.MP4"))
		end)

		it("returns nil for unknown extensions", function()
			assert.is_nil(media.detect_media_type("file.xyz"))
			assert.is_nil(media.detect_media_type("file.txt"))
			assert.is_nil(media.detect_media_type("file.pdf"))
		end)

		it("returns nil for files with no extension", function()
			assert.is_nil(media.detect_media_type("noextension"))
		end)

		it("handles paths with directories", function()
			assert.are.equal("image", media.detect_media_type("/home/user/photo.png"))
			assert.are.equal("audio", media.detect_media_type("C:\\Users\\sound.mp3"))
		end)
	end)

	describe("media_reference", function()
		it("generates img tag for images", function()
			assert.are.equal('<img src="photo.png">', media.media_reference("photo.png"))
			assert.are.equal('<img src="pic.jpg">', media.media_reference("pic.jpg"))
		end)

		it("generates sound tag for audio", function()
			assert.are.equal("[sound:voice.mp3]", media.media_reference("voice.mp3"))
			assert.are.equal("[sound:alarm.wav]", media.media_reference("alarm.wav"))
		end)

		it("generates sound tag for video", function()
			assert.are.equal("[sound:clip.mp4]", media.media_reference("clip.mp4"))
		end)

		it("generates sound tag for unknown extensions", function()
			assert.are.equal("[sound:file.xyz]", media.media_reference("file.xyz"))
		end)
	end)

	describe("basename", function()
		it("extracts filename from Unix paths", function()
			assert.are.equal("photo.png", media.basename("/home/user/photos/photo.png"))
		end)

		it("extracts filename from Windows paths", function()
			assert.are.equal("photo.png", media.basename("C:\\Users\\photo.png"))
		end)

		it("returns the filename when no path separator", function()
			assert.are.equal("photo.png", media.basename("photo.png"))
		end)
	end)
end)

describe("_attach_browse", function()
	it("calls get_media_files_names with pattern and callback arguments", function()
		local ankiconnect = require("anki.ankiconnect")
		local received_pattern = nil
		local received_callback_type = nil
		local original_fn = ankiconnect.get_media_files_names

		ankiconnect.get_media_files_names = function(pattern, on_result)
			received_pattern = pattern
			received_callback_type = type(on_result)
		end

		media._attach_browse(1)

		assert.are.equal("*", received_pattern)
		assert.are.equal("function", received_callback_type)

		ankiconnect.get_media_files_names = original_fn
	end)
end)

describe("Note.media", function()
	local function make_field(name, bufnr)
		return Field:new({
			editor_context = EditorContext:new({ bufnr = bufnr, winid = bufnr * 10, tabid = bufnr * 100 }),
			name = name,
		})
	end

	it("initializes media with empty tables by default", function()
		local n = Note:new({
			deck_name = "Default",
			model_name = "Basic",
			fields = { make_field("Front", 1) },
			tags = EditorContext:new({ bufnr = 2, winid = 3, tabid = 4 }),
		})
		assert.are.equal(0, #n.media.picture)
		assert.are.equal(0, #n.media.audio)
		assert.are.equal(0, #n.media.video)
	end)

	it("add_media adds picture entries", function()
		local n = Note:new({
			deck_name = "Default",
			model_name = "Basic",
			fields = { make_field("Front", 1) },
			tags = EditorContext:new({ bufnr = 2, winid = 3, tabid = 4 }),
		})
		n:add_media("picture", { url = "https://example.com/img.png", filename = "img.png", fields = { "Front" } })
		assert.are.equal(1, #n.media.picture)
		assert.are.equal("img.png", n.media.picture[1].filename)
	end)

	it("add_media adds audio entries", function()
		local n = Note:new({
			deck_name = "Default",
			model_name = "Basic",
			fields = { make_field("Front", 1) },
			tags = EditorContext:new({ bufnr = 2, winid = 3, tabid = 4 }),
		})
		n:add_media("audio", { url = "https://example.com/snd.mp3", filename = "snd.mp3", fields = { "Front" } })
		assert.are.equal(1, #n.media.audio)
		assert.are.equal("snd.mp3", n.media.audio[1].filename)
	end)

	it("add_media adds video entries", function()
		local n = Note:new({
			deck_name = "Default",
			model_name = "Basic",
			fields = { make_field("Front", 1) },
			tags = EditorContext:new({ bufnr = 2, winid = 3, tabid = 4 }),
		})
		n:add_media("video", { url = "https://example.com/clip.mp4", filename = "clip.mp4", fields = { "Back" } })
		assert.are.equal(1, #n.media.video)
		assert.are.equal("clip.mp4", n.media.video[1].filename)
	end)

	it("add_media throws error for invalid media type", function()
		local n = Note:new({
			deck_name = "Default",
			model_name = "Basic",
			fields = { make_field("Front", 1) },
			tags = EditorContext:new({ bufnr = 2, winid = 3, tabid = 4 }),
		})
		assert.has_error(function()
			n:add_media("invalid", {})
		end)
	end)

	it("add_media throws error for non-table entry", function()
		local n = Note:new({
			deck_name = "Default",
			model_name = "Basic",
			fields = { make_field("Front", 1) },
			tags = EditorContext:new({ bufnr = 2, winid = 3, tabid = 4 }),
		})
		assert.has_error(function()
			n:add_media("picture", "not a table")
		end)
	end)
end)
