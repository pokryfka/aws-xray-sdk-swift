import AWSLambdaEvents
import AWSLambdaRuntime
import AWSXRayRecorder
import AWSXRayRecorderLambda
import NIO

private struct ExampleLambdaHandler: EventLoopLambdaHandler {
    typealias In = Cloudwatch.ScheduledEvent
    typealias Out = Void

    private let recorder = XRayRecorder()

    private func doWork(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.submit { usleep(100_000) }.map { _ in }
    }

    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Void> {
        recorder.segment(name: "ExampleLambdaHandler", context: context) {
            self.doWork(on: context.eventLoop)
        }.always { _ in
            self.recorder.flush()
        }
    }
}

Lambda.run(ExampleLambdaHandler())
