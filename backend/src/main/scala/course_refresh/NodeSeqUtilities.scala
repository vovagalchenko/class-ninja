package course_refresh

import scala.xml.{Node, NodeSeq}

object NodeSeqUtilities {
  implicit class NodeSeqWithFilterBy(nodeSeq: NodeSeq) {
    def filterByLiteralAttribute(attrName: String, attrValue: String): NodeSeq = {
      filterByAttribute(attrName, _ == attrValue)
    }

    def filterByAttributePrefix(attrName: String, prefix: String): NodeSeq = {
      filterByAttribute(attrName, { idValue: String =>
        idValue.startsWith(prefix)
      })
    }

    def filterByLackOfAttribute(attrName: String): NodeSeq = {
      nodeSeq.filter(_.attribute(attrName).isEmpty)
    }

    def filterByAttribute(attrName: String, filter: (String => Boolean)): NodeSeq = {
      nodeSeq filter { node: Node =>
        node.attribute(attrName) match {
          case Some(id) => filter(id.text)
          case None => false
        }
      }
    }
  }
}
