// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/meme_game_web.ex",
    "../lib/meme_game_web/**/*.*ex"
  ],
  theme: {
    extend: {
      backgroundImage:{
        top_wave: "url('/images/top_wave.svg')",
        bottom_wave: "url('/images/bottom_wave.svg')"
      },
      colors: {
        accent: {
          50: "#ffc0da",
          100: "#ffb3d2",
          200: "#ffa6cb",
          300: "#ff9ac3",
          400: "#ff8dbc",
          500: "#FF81B5",
          600: "#e574a2",
          700: "#cc6790",
          800: "#b25a7e",
          900: "#994d6c",
        },
        primary: {
          50: "#bef3ea",
          100: "#b1f0e6",
          200: "#a4eee2",
          300: "#97ebde",
          400: "#8ae9da",
          500: "#7EE7D6",
          600: "#71cfc0",
          700: "#64b8ab",
          800: "#58a195",
          900: "#4b8a80"
        },
        secondary: {
          50: "#ffd8c1",
          100: "#ffd0b4",
          200: "#ffc8a8",
          300: "#ffc09b",
          400: "#ffb88f",
          500: "#ffb183",
          600: "#e59f75",
          700: "#cc8d68",
          800: "#b27b5b",
          900: "#996a4e"
        },
        normal: {
          50: "#a1a2a9",
          100: "#8e8f98",
          200: "#7c7c87",
          300: "#696a76",
          400: "#565765",
          500: "#444554",
          600: "#3d3e4b",
          700: "#363743",
          800: "#2f303a",
          900: "#282932"
        }
      }
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({matchComponents, theme}) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = {name, fullPath: path.join(iconsDir, dir, file)}
        })
      })
      matchComponents({
        "hero": ({name, fullPath}) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("spacing.6")
          if (name.endsWith("-mini")) {
            size = theme("spacing.5")
          } else if (name.endsWith("-micro")) {
            size = theme("spacing.4")
          }
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": size,
            "height": size
          }
        }
      }, {values})
    })
  ]
}
