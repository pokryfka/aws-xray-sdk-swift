# Types

  - [XRayRecorder.Config](/XRayRecorder_Config):​
    `XRayRecorder` configuration.
  - [XRayRecorder.Config.ContextMissingStrategy](/XRayRecorder_Config_ContextMissingStrategy):​
    Context missing strategy.
  - [XRayNoOpEmitter](/XRayNoOpEmitter):​
    Implements `XRayEmitter` which does not do anything.
  - [XRayRecorder.Segment.Encoding](/XRayRecorder_Segment_Encoding):​
    A type representing the ability to encode a `XRayRecorder.Segment` to a String with its JSON representation.
  - [XRayRecorder](/XRayRecorder):​
    XRay tracer.
  - [XRayRecorder.Segment](/XRayRecorder_Segment):​
    A segment records tracing information about a request that your application serves.
    At a minimum, a segment records the name, ID, start time, trace ID, and end time of the request.
  - [XRayRecorder.Segment.ID](/XRayRecorder_Segment_ID):​
    A 64-bit identifier in **16 hexadecimal digits**.
  - [XRayRecorder.TraceID](/XRayRecorder_TraceID)
  - [XRayRecorder.SampleDecision](/XRayRecorder_SampleDecision):​
    Sampling decision.
  - [XRayRecorder.TraceContext](/XRayRecorder_TraceContext):​
    XRay Trace Context propagated in a tracing header.
  - [XRayLogEmitter](/XRayLogEmitter):​
    "Emits" segments by logging them using provided logger instance.
  - [XRayUDPEmitter.Config](/XRayUDPEmitter_Config):​
    `XRayUDPEmitter` configuration.
  - [XRayUDPEmitter](/XRayUDPEmitter):​
    Send `XRayRecorder.Segment`s to the X-Ray daemon, which will buffer them and upload to the X-Ray API in batches.
    The X-Ray SDK sends segment documents to the daemon to avoid making calls to AWS directly.
  - [XRayUDPEmitter.EventLoopGroupProvider](/XRayUDPEmitter_EventLoopGroupProvider):​
    Specifies how `EventLoopGroup` will be created and establishes lifecycle ownership.

# Protocols

  - [XRayNIOEmitter](/XRayNIOEmitter):​
    A `SwiftNIO` `XRayEmitter`.
  - [XRayEmitter](/XRayEmitter):​
    A type representing the ability to emit `XRayRecorder.Segment`.

# Global Typealiases

  - [XRayContext](/XRayContext)
