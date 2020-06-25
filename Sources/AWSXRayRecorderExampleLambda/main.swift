import AWSLambdaEvents
import AWSLambdaRuntime
import AWSXRayRecorder
import AWSXRayRecorderLambda
import NIO

private struct ExampleLambdaHandler: EventLoopLambdaHandler {
    typealias In = Cloudwatch.ScheduledEvent
    typealias Out = Void

    private let recorder = XRayRecorder()
    private let emmiter: XRayEmmiter

    init(eventLoop: EventLoop) {
        emmiter = XRayEmmiter(eventLoop: eventLoop, endpoint: Lambda.env("XRAY_ENDPOINT"))
    }

    private func doWork(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.submit { usleep(100_000) }.map { _ in }
    }

    private func sendXRaySegments(on eventLoop: EventLoop? = nil) -> EventLoopFuture<Void> {
        emmiter.send(segments: recorder.removeReady(), on: eventLoop)
    }

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Void> {
        recorder.segment(name: "ExampleLambdaHandler", context: context) {
            self.doWork(on: context.eventLoop)
        }.flatMap {
            self.sendXRaySegments()
        }
    }
}

Lambda.run { context in ExampleLambdaHandler(eventLoop: context.eventLoop) }
