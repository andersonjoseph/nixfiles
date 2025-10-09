return {
    "cbochs/grapple.nvim",
    opts = {
        scope = "cwd"
    },
    event = { "BufReadPost", "BufNewFile" },
    cmd = "Grapple",
    keys = {
        { "M", "<cmd>Grapple toggle<cr>", desc = "Grapple toggle tag" },
        { "m", "<cmd>Grapple toggle_tags<cr>", desc = "Grapple open tags window" },
    },
}
