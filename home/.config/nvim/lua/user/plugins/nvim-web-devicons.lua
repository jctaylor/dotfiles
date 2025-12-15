-- The readme says this plugin "adds" nerd font icons. What they mean is that is uses Nerd fonts by using characters
-- in the Nerd font set as icons. It expects the terminal it is run in to be using Nerd fonts.
return {
  "nvim-tree/nvim-web-devicons",
  config = function()
    require("nvim-web-devicons").set_icon({
      gql = {
        icon = "",
        color = "#e535ab",
        cterm_color = "199",
        name = "GraphQL",
      },
    })
  end,
}
