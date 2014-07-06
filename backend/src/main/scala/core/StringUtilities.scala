package core

object StringUtilities {
  implicit class StringWithSafeId(string: String) {
    def toSafeId: String = {
      string.replaceAllLiterally(" ", "_").toUpperCase
    }
    def safeToInt: Int = {
      if (string == "") {
        0
      } else {
        string.toInt
      }
    }
  }
}
