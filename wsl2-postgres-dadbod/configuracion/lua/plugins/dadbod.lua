return {
  "tpope/vim-dadbod",
  "kristijanhusak/vim-dadbod-completion",
  {
    "kristijanhusak/vim-dadbod-ui",
    config = function()
      vim.g.db_ui_use_nerd_fonts = 1

      -- Abrir/cerrar el panel lateral
      vim.keymap.set("n", "<leader>d", "<cmd>DBUIToggle<CR>", { desc = "DBUI: Toggle panel lateral" })

      -- Cerrar el panel de resultados (dbout buffer)
      vim.keymap.set("n", "<leader>tt", function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
          if bufname:match("dbout") then
            vim.api.nvim_win_close(win, true)
          end
        end
      end, { desc = "Dadbod: Cerrar resultados" })

      -- Volver a mostrar el panel de resultados si el buffer dbout aún existe
      vim.keymap.set("n", "<leader>to", function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local name = vim.api.nvim_buf_get_name(buf)
          if name:match("dbout") then
            vim.cmd("split")
            vim.api.nvim_win_set_buf(0, buf)
            vim.cmd("wincmd J") -- moverlo abajo
            return
          end
        end
        vim.notify("No hay resultados recientes para mostrar (dbout buffer no existe).", vim.log.levels.WARN)
      end, { desc = "Dadbod: Volver a mostrar resultados" })

      -- Ejecutar consulta en línea actual o selección visual
      vim.keymap.set("n", "<leader>r", "<cmd>DB<CR>", { desc = "Dadbod: Ejecutar consulta actual" })
      vim.keymap.set("v", "<leader>r", ":DB<CR>", { desc = "Dadbod: Ejecutar consulta seleccionada" })

      -- Maximizar / restaurar panel de resultados dbout
      vim.keymap.set("n", "<leader>tm", function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
          if bufname:match("dbout") then
            -- Hacer que esta ventana ocupe casi todo el alto y ancho
            vim.api.nvim_set_current_win(win)
            vim.cmd("wincmd J")            -- mover abajo (opcional)
            vim.cmd("resize " .. (vim.o.lines - 5))  -- casi todo el alto
            vim.cmd("vertical resize " .. (vim.o.columns - 5))  -- casi todo el ancho
            return
          end
        end
        vim.notify("No se encontró buffer dbout para maximizar.", vim.log.levels.WARN)
      end, { desc = "Dadbod: Maximizar panel de resultados" })

      -- Restaurar tamaño del panel de resultados a valor “normal”
      vim.keymap.set("n", "<leader>tn", function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
          if bufname:match("dbout") then
            vim.api.nvim_set_current_win(win)
            vim.cmd("resize 10")            -- altura normal de 10 líneas
            vim.cmd("vertical resize 80")   -- ancho fijo de 80 columnas
            return
          end
        end
        vim.notify("No se encontró buffer dbout para restaurar.", vim.log.levels.WARN)
      end, { desc = "Dadbod: Restaurar panel de resultados" })
    end,
  },
}
