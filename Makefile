test: plenary.nvim
	nvim --headless -c "lua require(\"plenary.test_harness\").test_directory_command('tests/ {minimal_init = \"tests/minimal-init.nvim\"}')"

plenary.nvim:
	git clone git@github.com:nvim-lua/plenary.nvim.git

