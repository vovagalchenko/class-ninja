package core

import scala.xml.{Node, NodeSeq}

object NodeSeqUtilities {
  implicit class NodeSeqWithFilterBy(nodeSeq: NodeSeq) {
    def filterByAttribute(attrName: String, attrValue: String): NodeSeq = {
      nodeSeq filter { node: Node =>
        node.attribute(attrName) match {
          case Some(id) => id.text == attrValue
          case None => false
        }
      }
    }
  }
}
