# TDNetworking

This project contains the barebones of a networking stack, ready to be tailored to a projects specific needs.


## Description
Clear separation of concerns is one of the most valued yet hardest to achieve aspects of software development, so we have to be careful how we define the elements of our new stack.

Usually, when requesting data over the network, the following (over-simplified) steps should happen:

- we construct a URLRequest, which contains the URL, HTTP method, additional headers and encoding.
- we take this URLRequest and pass it to URLSession, so it can perform the the network request.
- we receive the network response and parse it.

Based on these steps, we can start to divide the three main layers our stack should have.

### Request setup

The framework introduces `TDNetworkRequest` object that holds every information needed for performing a network request. On a high level, these parameters are the request method, required headers, optional parameters for encoding and wether this request should contain specific authentication. 

In your project, you have to gather information on what types of requests you have to perform and define the requirements based on what you learn (thinking about required properties and their default values etc). 

There are endless possibilities on how to implement this object. I would like to show an example using the object oriented approach. I made the assumption that you might use different types of authentication, so I introduced an enum to store this information. As the enum has only two cases, it could be replaced by a Boolean, but having strong, named types give more clarity to our code.


### Request processing

This layer is where the network request is performed. Ideally, methods of this object should be as close to a pure functions as possible, meaning minimising change in internal state and having little to no side effects while executing the request.

To demonstrate the simplicity we should aim for, please see the example below.

protocol URLRequestProcessorInterface {
  var urlSession: URLSession { get }
  var urlSessionConfiguration: URLSessionConfiguration { get }

  func process(
    request: URLRequest,
    completion: @escaping (Result<HTTPURLResponse, Error>) -> Void
  )
}

By keeping this layer simple and independent, it can be used in a variety of use cases: communicating with your internal backend services, 3rd party providers (Firebase, any other analytics) etc.

### Parsing network response

Server responses can vary depending on the backend system itself, but variations can also come from within a system: for some requests you receive JSON, but for others only a simple status code. The framework provides methods in `TDNetworkManager` to support these scenarios.

## Future improvements to the framework:
- [ ] Add unit tests
- [ ] Add code linter and formatter (SwiftLint and SwiftFormat)
- [ ] Extensive documentation
- [ ] Support for uploading data
