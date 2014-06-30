package core

import dispatch.Defaults._
import dispatch.as.tagsoup.{NodeSeq => DNodeSeq}
import dispatch.{Http, Req, url}
import java.net.URLEncoder
import scala.concurrent.Future
import scala.xml.NodeSeq

object HTTPManager {
  def execute[T](request: HTTPRequest)(onSuccess: NodeSeq => T): Future[T] = {
    val req: Req = reqFromHTTPRequest(request)
    // Creating a new HTTP client every time. Here's where we will pick a random proxy to go through
    val httpDispatch: Http = new Http()
    val futureResult: Future[NodeSeq] = httpDispatch(req.OK(DNodeSeq(_)))
    futureResult.transform({ nodeSeq: NodeSeq =>
      val result: T = onSuccess(nodeSeq)
      httpDispatch.shutdown()
      result
    }, { t: Throwable =>
      httpDispatch.shutdown()
      t
    })
  }

  private def reqFromHTTPRequest(request: HTTPRequest): Req = {
    val fullURLString: String = {
      val qualifiedPath = request.root + request.path
      if (request.queryParams.size > 0) {
        val encoding: String = "UTF-8"
        val fullPath = request.queryParams.toSeq.foldLeft(qualifiedPath + "?") { (urlSoFar: String, pairToAdd: (String, String)) =>
          s"$urlSoFar${URLEncoder.encode(pairToAdd._1, encoding)}=${URLEncoder.encode(pairToAdd._2, encoding)}&"
        }
        fullPath.dropRight(1)
      } else {
        qualifiedPath
      }
    }
    url(fullURLString)
  }
}

class HTTPRequestFactory(root: String) {
  def apply(path: String, queryParams: Map[String, String] = Map.empty): HTTPRequest = {
    HTTPRequest(root, path, queryParams)
  }
}

case class HTTPRequest(
  root: String,
  path: String,
  queryParams: Map[String, String]
)
