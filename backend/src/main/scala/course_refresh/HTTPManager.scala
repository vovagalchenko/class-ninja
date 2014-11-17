package course_refresh

import java.net.{HttpCookie, URLEncoder}
import com.ning.http.client.AsyncHttpClientConfig.Builder
import com.ning.http.client.{RequestBuilder, Request}
import com.ning.http.client.cookie.Cookie
import com.ning.http.client.filter.{ResponseFilter, FilterContext, RequestFilter}
import scala.collection.JavaConverters._
import com.typesafe.scalalogging.slf4j.LazyLogging
import dispatch.Defaults._
import dispatch.as.tagsoup.{NodeSeq => DNodeSeq}
import dispatch.{Http, Req, url}
import scala.language.implicitConversions
import scala.collection.mutable
import scala.concurrent.Future
import scala.xml.NodeSeq

object HTTPManager extends LazyLogging {
  private val requests: mutable.HashMap[Int, String] = mutable.HashMap()
  val cookies: mutable.HashMap[String, List[HttpCookie]] = mutable.HashMap()

  val httpExecutor: Http = Http configure { builder: Builder =>
    val timeoutInMs = 360000
    val configuredBuilder = builder
      .setConnectionTimeoutInMs(timeoutInMs)
      .setRequestTimeoutInMs(timeoutInMs)
      .setFollowRedirects(true)
      .setIdleConnectionInPoolTimeoutInMs(timeoutInMs)
      .setIdleConnectionTimeoutInMs(timeoutInMs)
      .setWebSocketIdleTimeoutInMs(timeoutInMs)
      .addRequestFilter(new RequestFilter {
        override def filter(ctx: FilterContext[_]): FilterContext[_] = {
          val request = ctx.getRequest
          new FilterContext.FilterContextBuilder(ctx).request(enhancedRequestWithCookies(request)).build
        }
      })
      .addResponseFilter(new ResponseFilter() {
        override def filter(ctx: FilterContext[_]): FilterContext[_] = {
          stripCookies(ctx)
          ctx
        }
      })
    configuredBuilder
  }

  private def registerRequest(request: Request, httpManagerHashCode: String) = synchronized {
    requests += (request.hashCode -> httpManagerHashCode)
  }

  private def registerForCookies(httpManager: HTTPManager) = synchronized {
    cookies += (httpManager.hashCode.toString -> List[HttpCookie]())
  }

  private def cleanupCookieStorage(httpManager: HTTPManager) = synchronized {
    cookies -= httpManager.hashCode.toString
  }

  private def getHttpManagerHashCode(request: Request) =
    if (request.getParams == null) "unknown_http_manager" else request.getParams.getFirstValue("httpManager")

  private def stripCookies(ctx: FilterContext[_]) = synchronized {
    val httpManagerHashCode = getHttpManagerHashCode(ctx.getRequest)
    val newCookiesOption = cookies.get(httpManagerHashCode) map { existingCookies =>
      val headers = ctx.getResponseHeaders.getHeaders
      val cookieHeaders = headers.get("Set-Cookie")
      val cookieStringList = if (cookieHeaders == null) List() else cookieHeaders.asScala.toList
      val cookiesToAdd = cookieStringList.flatMap(HttpCookie.parse(_).asScala)
      existingCookies ++ cookiesToAdd
    }
    newCookiesOption foreach { newCookies =>
      cookies += (httpManagerHashCode -> newCookies)
    }
    requests -= ctx.getRequest.hashCode
  }

  implicit def cookieConversion(httpCookie: HttpCookie): Cookie =
    new Cookie(httpCookie.getName, httpCookie.getValue, httpCookie.getValue, httpCookie.getDomain, httpCookie.getPath, 0, httpCookie.getMaxAge.toInt, httpCookie.getSecure, httpCookie.isHttpOnly)

  private def enhancedRequestWithCookies(request: Request): Request = synchronized {
    val httpManagerHashCode = getHttpManagerHashCode(request)
    val enhancedRequest = cookies.get(httpManagerHashCode) map { listOfCookies =>
      def cookieAddHelper(requestBuilder: RequestBuilder, cookiesToAdd: List[HttpCookie]): RequestBuilder = {
        if (cookiesToAdd.size == 0) requestBuilder
        else cookieAddHelper(requestBuilder.addOrReplaceCookie(cookiesToAdd(0)), cookiesToAdd.tail)
      }
      val r = new RequestBuilder(request)
      r.resetCookies()
      cookieAddHelper(r, listOfCookies).build()
    }
    enhancedRequest.getOrElse(request)
  }

  def shutdown() = {
    logger.info("Shutting down the HTTP executor")
    httpExecutor.shutdown()
    Http.shutdown()
  }

  def withHTTPManager[T](work: HTTPManager => Future[T]): Future[T] = withHTTPManager(manageCookies = false)(work)

  def withHTTPManager[T](manageCookies: Boolean = false)(work: HTTPManager => Future[T]): Future[T] = {
    val httpManager = new HTTPManager()
    if (manageCookies)
      registerForCookies(httpManager)
    val result = work(httpManager)
    result onComplete { _ =>
      if (manageCookies) cleanupCookieStorage(httpManager)
    }
    result
  }
}

class HTTPManager extends LazyLogging {

  def execute[T](request: HTTPRequest)(onSuccess: NodeSeq => T): Future[T] =
    this.execute(reqFromHTTPRequest(request))(onSuccess)

  def get[T](urlString: String)(onSuccess: NodeSeq => T): Future[T] =
    this.execute(url(urlString))(onSuccess)

  private def execute[T](req: Req)(onSuccess: NodeSeq => T): Future[T] = {
    val futureResult: Future[NodeSeq] = HTTPManager.httpExecutor(req.OK(DNodeSeq(_)))
    futureResult.map(onSuccess)
  }

  private def addCookiesHelper(request: Req, cookiesToAdd: List[Cookie]): Req = {
    if (cookiesToAdd.size == 0) request
    else {
      val newReq = request.addCookie(cookiesToAdd(0))
      addCookiesHelper(newReq, cookiesToAdd.tail)
    }
  }

  private def addParametersHelper(request: Req, parameters: Seq[(String, String)]): Req = {
    if (parameters.size == 0) request
    else {
      val newReq = request.addParameter(parameters(0)._1, parameters(0)._2)
      addParametersHelper(newReq, parameters.tail)
    }
  }

  def reqFromHTTPRequest(request: HTTPRequest): Req = {
    val fullURLString: String = {
      val qualifiedPath = request.root + request.path
      if (request.queryParams.size > 0) {
        val urlEncodedQueryParams: String = mapToURLEncodedString(request.queryParams)
        qualifiedPath + "?" + urlEncodedQueryParams
      } else {
        qualifiedPath
      }
    }
    val req = url(fullURLString)
      .setMethod(request.method)
      .setParameters(Map("httpManager" -> Seq(this.hashCode().toString)))
    request.body match {
      case Some(b) => addParametersHelper(req, b.toSeq)
      case None    => req
    }
  }

  private def mapToURLEncodedString(map: Map[String, String]): String = {
    val encoding = "UTF-8"
    map.toSeq.foldLeft("") { (urlSoFar: String, pairToAdd: (String, String)) =>
      s"$urlSoFar${URLEncoder.encode(pairToAdd._1, encoding)}=${URLEncoder.encode(pairToAdd._2, encoding)}&"
    }.dropRight(1)
  }
}

class HTTPRequestFactory(root: String) {
  def apply(path: String, method: String = "GET", queryParams: Map[String, String] = Map.empty): HTTPRequest =
    HTTPRequest(root, path, method, queryParams, None)

  def apply(path: String, bodyMap: Map[String, String]): HTTPRequest =
    HTTPRequest(root, path, "POST", Map[String, String](), Some(bodyMap))
}

case class HTTPRequest(
  root: String,
  path: String,
  method: String,
  queryParams: Map[String, String],
  body: Option[Map[String, String]]
)
