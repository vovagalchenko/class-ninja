package course_refresh

object StringUtilities {
  implicit class EnrichedString(string: String) {

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

    def removeExtraneousSpacing: String = string
      .replaceAll("<br>", " ")
      .replaceAll("\u00A0", " ")
      .replaceAll("\\s", " ")
      .trim
      .replaceAll(" {2,}", " ")
  }
}
