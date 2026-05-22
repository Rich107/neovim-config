local M = {}

local WINDOW_NAME = "html-serve"
local PORT = 6967
local NTFY_TOPIC = "phone-re-supersecret-local-ip"

local PY_SERVER = [[
import http.server,socketserver,os,mimetypes
F=os.environ["HTML_FILE"]
T=mimetypes.guess_type(F)[0] or "application/octet-stream"
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            with open(F,"rb") as fh: d=fh.read()
        except FileNotFoundError:
            self.send_error(404); return
        self.send_response(200)
        self.send_header("Content-Type",T)
        self.send_header("Content-Length",str(len(d)))
        self.end_headers()
        self.wfile.write(d)
socketserver.TCPServer.allow_reuse_address=True
print("Serving "+F+" on http://0.0.0.0:%d/"%]] .. PORT .. [[)
socketserver.TCPServer(("0.0.0.0",]] .. PORT .. [[),H).serve_forever()
]]

local function get_local_ip()
	local iface = vim.fn.system("route -n get default 2>/dev/null | awk '/interface:/ {print $2}'"):gsub("%s+$", "")
	if iface ~= "" then
		local ip = vim.fn.system("ipconfig getifaddr " .. iface .. " 2>/dev/null"):gsub("%s+$", "")
		if ip ~= "" then
			return ip
		end
	end

	for i = 0, 9 do
		local ip = vim.fn.system("ipconfig getifaddr en" .. i .. " 2>/dev/null"):gsub("%s+$", "")
		if ip ~= "" then
			return ip
		end
	end

	return "localhost"
end

function M.open_in_browser()
	local full_path = vim.fn.expand("%:p")
	if full_path == "" then
		vim.notify("No file to open in browser", vim.log.levels.WARN)
		return
	end

	vim.ui.open(full_path)
	vim.notify("Opened in browser: " .. full_path, vim.log.levels.INFO)
end

function M.serve_in_tmux()
	local full_path = vim.fn.expand("%:p")
	if full_path == "" then
		vim.notify("No file to serve", vim.log.levels.WARN)
		return
	end

	local cmd = string.format(
		"HTML_FILE=%s python3 -c %s",
		vim.fn.shellescape(full_path),
		vim.fn.shellescape(PY_SERVER)
	)

	local ip = get_local_ip()
	local url = string.format("http://%s:%d/", ip, PORT)
	local local_url = string.format("http://localhost:%d/", PORT)

	vim.fn.setreg("+", url)
	vim.fn.setreg('"', url)

	local msg = string.format(
		"Serving %s\n  LAN:    %s  (copied to clipboard)\n  Local:  %s",
		full_path,
		url,
		local_url
	)

	vim.fn.jobstart({
		"curl", "-s", "-X", "POST",
		"-H", "Title: nvim file server",
		"-H", "Click: " .. url,
		"-d", vim.fn.fnamemodify(full_path, ":t"),
		"https://ntfy.sh/" .. NTFY_TOPIC,
	}, { detach = true })

	local tmux_env = vim.fn.getenv("TMUX")
	if tmux_env == vim.NIL or tmux_env == "" then
		vim.cmd("split | terminal " .. cmd)
		vim.notify(msg, vim.log.levels.INFO)
		return
	end

	local check_cmd = string.format("tmux list-windows -F '#{window_name}' | grep -q '^%s$'", WINDOW_NAME)
	vim.fn.system(check_cmd)
	local exists = vim.v.shell_error == 0

	if exists then
		vim.fn.system(string.format("tmux select-window -t '%s'", WINDOW_NAME))
		local send_cmd = string.format(
			"tmux send-keys -t '%s' C-c C-u %s Enter",
			WINDOW_NAME,
			vim.fn.shellescape(cmd)
		)
		vim.fn.system(send_cmd)
	else
		local create_cmd = string.format("tmux new-window -n '%s' %s", WINDOW_NAME, vim.fn.shellescape(cmd))
		vim.fn.system(create_cmd)
	end

	vim.notify(msg, vim.log.levels.INFO)
end

return M
