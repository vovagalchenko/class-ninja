package core

object StringUtilities {
  implicit class StringWithSafeId(string: String) {
    def toSafeId: String = {
      string.replaceAllLiterally(" ", "_").toUpperCase
    }
  }
}
