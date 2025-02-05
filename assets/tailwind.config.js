// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/omedis_web.ex",
    "../lib/omedis_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        "bg-primary": "rgba(var(--bg-primary))",
        "bg-secondary": "rgba(var(--bg-secondary))",
        "txt-primary": "rgba(var(--txt-primary))",
        "txt-secondary": "rgba(var(--txt-secondary))",
        "btn-border": "rgba(var(--btn-border))",
        "section-border": "rgba(var(--section-border))",
        "icons-txt-secondary": "rgba(var(--icons-txt-secondary))",
        "form-subtitle-txt": "rgba(var(--form-subtitle-txt))",
        "form-txt-primary": "rgba(var(--form-txt-primary))",
        "form-error-text": "rgba(var(--form-error-text))",
        "form-error-bg": "rgba(var(--form-error-bg))",
        "form-info-primary": "rgba(var(--form-info-primary))",
        "form-input-border": "rgba(var(--form-input-border))",
        "form-radio-checked-primary": "rgba(var(--form-radio-checked-primary))",
        "form-radio-checked-secondary": "rgba(var(--form-radio-checked-secondary))",
        "form-dropdown-bg": "rgba(var(--form-dropdown-bg))",
        "form-dropdown-border": "rgba(var(--form-dropdown-border))",
        "form-dropdown-shadow": "rgba(var(--form-dropdown-shadow))",
        "form-dropdown-txt": "rgba(var(--form-dropdown-txt))",
        "form-border-focus": "rgba(var(--form-border-focus))",
        "client-form-btn-bg": "rgba(var(--client-form-btn-bg))",
        "client-form-btn-txt": "rgba(var(--client-form-btn-txt))",
        "form-error-popup-bg": "rgba(var(--form-error-popup-bg))",
        "form-error-popup-txt": "rgba(var(--form-error-popup-txt))",
      },
      fontFamily: {
        openSans: ["Open Sans", "serif"],
      },
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
