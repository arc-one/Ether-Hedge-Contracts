pragma solidity ^0.5.0;
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract Meta is Ownable {

    // Meta variables

    string public name;
    string public description;
    string public urlWebVersion;
    string public urlDownloadVersion;
    string public urlMobileVersion;
    string public author;
    bytes32[] keywords;

    address public depositoryAddress;
    address public settingsAddress;
    address public contractToken;

    constructor(
        string memory _name, 
        string memory _description,
        string memory _author,
        string memory _urlWebVersion,
        string memory _urlDownloadVersion,
        string memory _urlMobileVersion,


        address _depositoryAddress,
        address _settingsAddress,
        address _contractToken,

        bytes32[] memory _keywords
    )
        public Ownable() {
            transferOwnership(msg.sender);
            name = _name;
            description = _description;
            author = _author;
            urlWebVersion = _urlWebVersion;
            urlDownloadVersion = _urlDownloadVersion;
            urlMobileVersion = _urlMobileVersion;
            depositoryAddress = _depositoryAddress;
            settingsAddress = _settingsAddress;
            contractToken = _contractToken;
            keywords = _keywords;
        }


    function setName (string memory _name) public onlyOwner {
        name = _name;
    }

    function setDescription (string memory _description) public onlyOwner {
        description = _description;
    }

    function setUrlDownloadVersion (string memory _urlDownloadVersion) public onlyOwner {
        urlDownloadVersion = _urlDownloadVersion;
    }

    function setUrlMobileVersion (string memory _urlMobileVersion) public onlyOwner {
        urlMobileVersion = _urlMobileVersion;
    }

    function setKeywords (bytes32[] memory _keywords) public onlyOwner {
        keywords = _keywords;
    }






}
