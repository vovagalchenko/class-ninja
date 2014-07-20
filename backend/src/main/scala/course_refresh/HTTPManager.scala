package course_refresh

import java.net.URLEncoder

import com.ning.http.client.AsyncHttpClientConfig.Builder
import com.typesafe.scalalogging.slf4j.LazyLogging
import dispatch.Defaults._
import dispatch.as.tagsoup.{NodeSeq => DNodeSeq}
import dispatch.{Http, Req, url}

import scala.concurrent.Future
import scala.xml.NodeSeq

object HTTPManager extends LazyLogging {

  val httpExecutor: Http = Http configure { builder: Builder =>
    val timeoutInMs = 360000
    builder
      .setConnectionTimeoutInMs(timeoutInMs)
      .setRequestTimeoutInMs(timeoutInMs)
      .setIdleConnectionInPoolTimeoutInMs(timeoutInMs)
      .setIdleConnectionTimeoutInMs(timeoutInMs)
      .setWebSocketIdleTimeoutInMs(timeoutInMs)
  }

  def execute[T](request: HTTPRequest)(onSuccess: NodeSeq => T): Future[T] = {
    this.execute(reqFromHTTPRequest(request))(onSuccess)
  }

  def get[T](urlString: String)(onSuccess: NodeSeq => T): Future[T] = {
    this.execute(url(urlString))(onSuccess)
  }

  private def execute[T](req: Req)(onSuccess: NodeSeq => T): Future[T] = {
    val futureResult: Future[NodeSeq] = httpExecutor(req.OK(DNodeSeq(_)))
    futureResult map { nodeSeq: NodeSeq =>
      onSuccess(nodeSeq)
    }
  }

  def reqFromHTTPRequest(request: HTTPRequest): Req = {
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

  def shutdown() = {
    logger.info("Shutting down the HTTP executor.")
    httpExecutor.shutdown()
    Http.shutdown()
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
