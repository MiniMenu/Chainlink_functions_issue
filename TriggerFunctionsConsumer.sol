// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {FunctionsClient} from "@chainlink/contracts@1.1.0/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts@1.1.0/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {Ticket} from "./Ticket.sol";

/// @notice Interface to interact with Ticket.sol
interface TicketInterface {
   function updateMetaData(string memory _score) external;
}
/**
 * @title This contract triggers chainlink functions to get the latest score. 
 */
contract TriggerFunctionsConsumer is FunctionsClient{
    using FunctionsRequest for FunctionsRequest.Request;

    // @notice State variables to store the last request ID, response, and error
    bytes32 internal s_lastRequestId;
    bytes internal s_lastResponse;
    bytes internal s_lastError;

    // @notice Custom error type
    error UnexpectedRequestID(bytes32 requestId);

   /**
       @notice Event to trigger the response of the Chainlink Functions
       @param requestId The requestId, to keep a track of the request 
       @param score Score returned from the API
       @param response Response of the Chainlink Functions request
       @param err Response of the Chainlink Functions request if an error has occured 
    */
    event Response(
        bytes32 indexed requestId,
        string score,
        bytes response,
        bytes err
    );

    address public router = 0xC22a79eBA640940ABB6dF0f7982cc119578E11De;
    bytes32  public donID =
        0x66756e2d706f6c79676f6e2d616d6f792d310000000000000000000000000000;
    uint32 public gasLimit = 100000;

    // @notice Javascript code to get the API results
    string  public  source =
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://test-project-git-main-minimenus-projects.vercel.app/api/football`"  
        "});"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"  
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(data.result);";

 
    // @notice State variable to store the returned score result
    string public score;

    /// @notice Stores the NFTMetaDataGeneratorInterface
    TicketInterface instanceOfTicket;

    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    // _ticketAddress: 0xfaD0F7Ddb57BA9Fce945C299887eC6900d1EfADA
    constructor(address _ticketAddress) 
    FunctionsClient(router) {
        instanceOfTicket = TicketInterface(_ticketAddress);
    }

    /**
     * @notice Sends an HTTP request for character information
     * @param subscriptionId The ID for the Chainlink subscription
     * @param args The arguments to pass to the HTTP request
     * @return requestId The ID of the request
     */
    function sendRequest(
        uint64 subscriptionId,
        string[] calldata args
    ) external returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request
 
        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );
 
        return s_lastRequestId;
    }
 

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        // Update the contract's state variables with the response and any errors
        s_lastResponse = response;
        score = string(response);
        s_lastError = err;
        // updateMetaData(score);

        // Emit an event to log the response
        emit Response(requestId, score, s_lastResponse, s_lastError);
    }
    

    function updateMetaData(string memory _score) public  {
        instanceOfTicket.updateMetaData(_score);
    }

}