import AWSLambdaEvents
import AWSLambdaRuntime
import AWSXRayRecorder
import AWSXRayRecorderLambda
import AWSXRayUDPEmitter
import NIO

private struct ExampleLambdaHandler: EventLoopLambdaHandler {
    typealias In = Cloudwatch.ScheduledEvent
    typealias Out = Void

    private let recorder = XRayRecorder()
    private let emmiter = XRayUDPEmitter()

    private func doWork(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.submit { usleep(100_000) }.map { _ in }
    }

    private func sendXRaySegments() -> EventLoopFuture<Void> {
        emmiter.send(segments: recorder.removeAll())
    }

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Void> {
        recorder.segment(name: "ExampleLambdaHandler", context: context) {
            self.doWork(on: context.eventLoop)
        }.flatMap {
            self.sendXRaySegments()
        }
    }
}

Lambda.run(ExampleLambdaHandler())
