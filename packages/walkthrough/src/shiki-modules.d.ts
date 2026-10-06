declare module 'shiki/langs/*.mjs' {
  import type { LanguageRegistration } from 'shiki/core'
  const lang: LanguageRegistration
  export default lang
}

declare module 'shiki/themes/*.mjs' {
  import type { ThemeRegistrationAny } from 'shiki/core'
  const theme: ThemeRegistrationAny
  export default theme
}
