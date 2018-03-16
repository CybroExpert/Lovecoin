pragma solidity ^0.4.2;
 
 
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
 
contract Ownable {
 
 
    address public owner;
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
 
    modifier onlyOwner()  {
        require(
            msg.sender == owner
            );
            _;
    }
    
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
 
    function Ownable () public {
        owner = msg.sender;
    }
}
 
/**
 * @title contract Lovecoincore.
 * @dev Lovecoincore is basically an ERC721 token.
 * @author Blockchain Expert.
*/
contract Lovecoincore is Ownable{
        //@param NAME is defines the name of the token as ERC721 standared  
        string public constant NAME = "Lovecoin";
        //@param SYMBOL defines the ERC721 standared symbol for token
        string public constant SYMBOL = "LOVE";
        //@param RATE defines cost of 1 token in wei equals 0.0143 ETH.
        uint256 public constant RATE = 14300000000000000;
        //@param totalSupply defines number of tokens created by the smartcontract yet
        uint256 public totalSupply = 0;
        //@param totalBids defines total number of bids created yet
        uint256 public totalBids = 0;
        //@param redeemCount defines total redeems are applied this count is limited to 5000. and the 5000 is  
        //allowed to create for developers and owner allowed users
        uint256 public redeemCount = 0;
        uint256 public saleCount = 0;
 
        /**
         * @param totalOwned is the two dimensional mapping from the address to uint which stores
         * the love coin balance curresponds coin owner
         * @param bid is the mapping from BID structure to the uint which stores the highest price
         * bid for each coin
         * @param lovecoin is the mapping from uint to the Love structure which stores each love coin
         */
          
        // @param totalOwned is used to store the number of coin owned by each account
        mapping (address => uint256) totalOwned;
        // @param bid is used to store Bids  
        mapping (uint256 => Bid) bid;
        // @param lovecoin is used to store the Love coins
        mapping (uint256 => Love) lovecoin;
        // @param redeem stores the redeem status(true or false) for any account that get the permission to redeem coin
        mapping (address => bool) redeem;
        
        /**
         * @param Love is a structure consist of Coin id, Selling price of coin, address of coin owner,
         * data to be encoded in the coin, ststus of selling availability.
          */
         
        // @param Love is a structure which consist of coin attributes, Each Love coin is combined of these unique value
        // each time creating a Love coin will generate an instance of this structure with the attributes
        // This is the skeleton of the ERC721 standared token with unique Id and data without fungiability
        struct Love {
             
            // @param coinID is the unique id. starts from 1 and end at 100000. this is the unique id to identify each of the love coin token
            // coinID is uint256 type value  
            uint256 coinID;
            // @param sellPrice defines the selling price of a generated coin
            // by default, this will be 0.0143 ETH (normal token cost), when the token sale in future, user can upadte this sellPrice
            uint256 sellPrice;
            // @param coinOwner is defines the owner of the particular coin. this should be a valid ethereum address.
            // this can't be set manually and this will automatically fetch from the wallet (Metmask like wallet)
            address coinOwner;
            // @param data stores the data to encoded in the coin. this is the hexa decimal format of concatenated string of  
            // the two Names that the user would like to add to the coin.
            // data should be read from the frontend as string and it will concatenated and pass to the function .
            // bytes32 data type automatically made the type coversion and it will generate a hexadecimal value of the string.
            // bytes32 used since it consume less storage space and EVM(Ethereum Virtual Machine) works with 32 bytes of data
            // so here EVM doesn't need coversion and directly process the 32 bytes of data. this will readuce tha gas limit and token creation cost
            bytes32 data;
            // @param sellAvailability store the status whether the coin has to sell or not.  sellAvailability is a bool type variable
            // it initially set to false and when the coin holder call readytoSell function this value become true.
            bytes message;
            bool sellAvailability;
            
        }
        /**
         * @param Bid is a structure combined of Bidding data including Coin id, Bidding amount, address of bidder
         * status of bid ApprovalStatus
         *  
         */
        
        struct Bid {
           
            // @param coinID reference to the coin ID that going to bid.  
            uint256 coinID;
            // @param bidAmount is uint256 type Bid variable to store the amount of ether for the bid.
            uint256 bidAmount;
            // @param bidBy is the address which stores the address of bidder.
            address bidBy;
            // @param ApprovalStatus is the status of bid. toggle true and false for a coin when bid is created and claimed
            bool ApprovalStatus;
        }
        
        /**
         * @dev createLove is a payable function it accepts only 14300000000000000 wei(0.0143 ETH), and create a love coin in the  
         * ownership of the sender
         * this function throws when the amount send to the contract is less or greater than 0.016 ETH
         * @dev isSoldout function ensure the availability of coin (ie: total production less than 1 lakh)
         * @dev the amount send to the function is the cost of the coin and this will transfer to the contract deployer
         * @dev once the correct amount paid and coin generated. then the amount of ether no more retrived.
         */
          
        function () public payable {
             
             
            // function to generate a fresh lovecoin with a unique id          
            require(
                msg.value > 0 &&
                // RATE is the cost of coin
                msg.value == RATE &&
                // check wether the coin is soldout or not
                isSoldout() == false
                );
                // Here we create a dummy Love structure called propose to temporarly add the coin data
                // and we will finally add the data into the structure array
                Love memory propose;
                //total supply should be increment befor the starting of the process since we take the total supply count as the  
                // refernce for the coin id
                totalSupply++;
                propose.coinID = totalSupply;
                //coin owner is set as the the user account using msg.sender
                propose.coinOwner = msg.sender;
                // the dummy is added to the original lovecoin data store
                lovecoin[totalSupply] = propose;
                // @param totalOwned is the balance of msg.sender this will increment finally
                totalOwned[msg.sender] += 1;
                // in case the value that passed is 0 which means that this transaction was a redeem so the redeem count will icremented by 1
                // for the future reference
                 
                             // after the completion of coin ctreation the the amount of ether that provided by the msg.sender as the cost of the coin
                // will send to the Lovecoin Smartcontract deployer account
            owner.transfer(msg.value);    
            // Event CreateLove is called to add the creation details to the block which includes the sender address and the coin Id
            CreateLove(msg.sender, totalSupply);
        
        }
 
        function createLove () public payable returns(bool){
            // function to generate a fresh lovecoin with a unique id          
            require(
                // RATE is the cost of coin
                (msg.value == RATE ||
                // For the redeem purpose of 1000 coins we check whether the account holder has added to the redeem array
                ((msg.sender == owner ||
                redeem[msg.sender] == true) &&
                // redeem count should be less than 10% of capital
                redeemCount < 5000)) &&  
                // check wether the coin is soldout or not
                isSoldout() == false
                );
                // Here we create a dummy Love structure called propose to temporarly add the coin data
                // and we will finally add the data into the structure array
                Love memory propose;
                //total supply should be increment befor the starting of the process since we take the total supply count as the  
                // refernce for the coin id
                totalSupply++;
                propose.coinID = totalSupply;
                //coin owner is set as the the user account using msg.sender
                propose.coinOwner = msg.sender;
                // the dummy is added to the original lovecoin data store
                lovecoin[totalSupply] = propose;
                // @param totalOwned is the balance of msg.sender this will increment finally
                totalOwned[msg.sender] += 1;
                // in case the value that passed is 0 which means that this transaction was a redeem so the redeem count will icremented by 1
                // for the future reference
                if(msg.value==0)    {
                    redeemCount++;
                // the redeem status of the msg.sender is set as false to avoid dual spending of redeem
                    if(redeem[msg.sender] == true) {
                        redeem[msg.sender]=false;
                    }
                }
                             // after the completion of coin ctreation the the amount of ether that provided by the msg.sender as the cost of the coin
                // will send to the Lovecoin Smartcontract deployer account
            owner.transfer(msg.value);    
            // Event CreateLove is called to add the creation details to the block which includes the sender address and the coin Id
            CreateLove(msg.sender, totalSupply);
            return true;
                
        }
        
 
        /**
         * @dev getLoveinfo is a constant function will return the stored informations of a coin  
         * it will accept valid coin id, throws when invalid coin id is entered
         */
        function getLoveinfo(uint256 _coinID) external view returns(address _owner,bytes32 _data,bytes _message) {
        // This function will throws if the coin Id is invalid
            require(
                _coinID > 0 &&
                _coinID <= totalSupply  
                );
        // getLoveinfo return the coinOwner address and the data embedded in coin  
            return(lovecoin[_coinID].coinOwner,lovecoin[_coinID].data,lovecoin[_coinID].message);
        }
        
        /**
         * @dev changeOwner is a internal callable function which will change the ownership of a coin
         * it only accept valid ethereum address and valid coin id and function change the ownership
         * to the given address
         * function will throw if the address or coin Id is invalid and if the msg.sender is not  
         * the coin owner
         */  
 
        function changeOwner(address _to, uint256 _coinID) internal {  
        // This function will Throw if the coin id is invalid , the msg.sender is not the owner of coin
        // and if the address is not valid
            require(
                _to != 0 &&
                _coinID > 0 &&
                totalSupply >= _coinID &&
                lovecoin[_coinID].coinOwner == msg.sender  
                );
                // change the owner of the coin as the new owner from the address variable _to
                lovecoin[_coinID].coinOwner = _to;  
                // update the coin balance of sender as decrement by one
                totalOwned[msg.sender] -= 1;
                // update the coin balance of reciepient ad decerement by one
                totalOwned[_to] += 1;
                // call the event to store the change ownership details in the block
                LoveTransfer(msg.sender,_to,_coinID);
 
            
        }
        
        /**
         * @dev function listLove will list the entire coins and their owners
         *  
         */
        function listLove() public constant returns(uint256[],address[])  {
             
                // this function will throw if the msg.sender is not the contractr deployer
                // this constant function is restricted to the owner only because the blockchain reading time may be high
                // since it recieves largest amont of elemsnts upto 50000 this may result time lag so to avoid un necessory  
                // call to this function
                require(
                    owner == msg.sender
                    );
                // decalring length with the total supply to inititliase the array of coins and owners with the length  
                uint256 length = totalSupply+1;
                uint256[] memory coinIDs = new uint256[](length);
                address[] memory owners = new address[](length);
                
                
                //looping the coinIDs and check wether the id is availble to sell , then it added to the selling list for diplay
                for(uint256 i = 1; i<length; i++)  {
                        Love memory lovewall;
                        lovewall = lovecoin[i];
                        coinIDs[i]=lovewall.coinID;  
                        owners[i]=lovewall.coinOwner;
                }
                 return (coinIDs,owners);
        }
        
        /**
         * @dev function giftLove is gift the coin to other valid ethereum addresses.  
         * this will change the ownership to the given addresses
         * and allow to change the encoded data in the coinOwner
         * throws when invalid coin id or sender is not the owner of coin
         */  
        function giftLove(uint256 _coinID, address _to, bytes32 _data,bytes _message) public returns (bool) {  
                //throws if the coin is invalid or the sender is not the owner of the coin.
                require(
                    _to != 0 &&
                    lovecoin[_coinID].coinOwner == msg.sender &&
                    _coinID > 0 &&
                    totalSupply >= _coinID
                        );  
                //first operation done by giftLove is to change the ownership of the coin from current Owner to new owner ie: address of _to  
                    changeOwner(_to, _coinID);
                    
                    lovecoin[_coinID].data = _data;
                    lovecoin[_coinID].message = _message;
                    
                    return true;
 
        }
        
        function allowRedeem(address _owner) public onlyOwner returns(bool) {
             
            require(
                _owner != 0 &&
                msg.sender == owner &&
                redeem[_owner] == false
                );
                 
                redeem[_owner] = true;
                return true;
                
        }
        
        /**
         * @dev function readytoSell change the sell status of coin. it will accept the coin Id and amount for sale
         * and then added to the marketplace
         * throws when ivalid coin id or msg.sender is not the owner
         */  
        function readytoSell(uint256 _coinID,uint256 _amount) public returns(bool)   {
            require(
                    _coinID > 0 &&
                    totalSupply >= _coinID &&
                    lovecoin[_coinID].coinOwner == msg.sender
                    );
                    
                    lovecoin[_coinID].sellAvailability = true;
                    lovecoin[_coinID].sellPrice = _amount;
                    saleCount++;
                    
                
                    return true;
        }
         
        /**
         * @dev cancelSale will cancel the sale of a coin
         * throws when coin id is invalid or invalid address
         */  
        function cancelSale(uint256 _coinID) public returns(bool)   {
             
            require(
                _coinID > 0 &&
                totalSupply >= _coinID &&
                lovecoin[_coinID].coinOwner == msg.sender &&
                lovecoin[_coinID].sellAvailability == true  
                );   
                 
                lovecoin[_coinID].sellAvailability = false;
                lovecoin[_coinID].sellPrice = RATE;
                saleCount--;
                 
                return true;
        }
        
        
        /**
         * @dev saleList function returns the list of coins which are about to sell.
         * which includes coinId, owner and amount to buy the coinId
         */
        function saleList() public constant returns(uint256[],address[],uint256[])    {
             
            uint256 length = totalSupply+1;
            uint256 index=0;
            uint256[] memory coinIDs = new uint256[](saleCount);
            address[] memory owners = new address[](saleCount);
            uint256[] memory sellPrices = new uint256[](saleCount);
                
                
                
                for(uint256 i = 1; i<length; i++)  {
                    if(lovecoin[i].sellAvailability==true)  {
                        Love memory lovewall;
                        lovewall = lovecoin[i];
                        coinIDs[index]=lovewall.coinID;  
                        owners[index]=lovewall.coinOwner;
                        sellPrices[index] = lovewall.sellPrice;
                        index++;    
                        }
                    }
                 return (coinIDs,owners,sellPrices);
        }
 
        
        function bidcoin(uint256 _coinID, uint256 _amount) public returns(bool) {
             
            require(
                _coinID > 0 &&
                totalSupply >= _coinID &&
                _amount > 0 &&
                _amount >= bid[_coinID].bidAmount &&
                bid[_coinID].ApprovalStatus == false
                );
                
                Bid memory newBid;
                totalBids++;
                newBid.coinID = _coinID;
                newBid.bidBy = msg.sender;
                newBid.bidAmount = _amount;
                bid[_coinID] = newBid;
        }
        
        function cancelBid(uint256 _coinID) public returns (bool)
        {
            require(lovecoin[_coinID].coinOwner == msg.sender &&
            bid[_coinID].bidAmount > 0
            );
            delete bid[_coinID];
            return true;
        }
        
        function cancelBidApproval(uint256 _coinID) public returns(bool)
        {
            require(lovecoin[_coinID].coinOwner == msg.sender &&
            bid[_coinID].bidAmount > 0 &&
            bid[_coinID].ApprovalStatus == true
            );
             
            bid[_coinID].ApprovalStatus = false;
            return true;
        }
        
        function showBid(uint256 _coinID) public constant returns(uint256,address) {
                require(
                    _coinID > 0 &&
                    totalSupply >= _coinID
                    );
                return(bid[_coinID].bidAmount,bid[_coinID].bidBy);
                
        }
 
        function approveBid(uint256 _coinID) public returns (bool) {
                
                require(
                        _coinID > 0 &&
                        totalSupply >= _coinID &&
                        lovecoin[_coinID].coinOwner == msg.sender &&
                        bid[_coinID].bidAmount != 0  
                        
                        );         
                        
                        bid[_coinID].ApprovalStatus=true;
                        return true;  
        }
        
        function totalredeemCount() public view returns(uint256)
        
        {
            require(msg.sender == owner);
             
            return(redeemCount);
            
        }
        
        function postSale(uint256 _coinID) public payable returns(bool) {
            require(lovecoin[_coinID].sellAvailability == true &&
                    msg.value == lovecoin[_coinID].sellPrice
                     
            );
            address _currentOwner =  lovecoin[_coinID].coinOwner;
      
           lovecoin[_coinID].coinOwner = msg.sender;  
           // update the coin balance of sender as decrement by one
            totalOwned[_currentOwner] -= 1;
            // update the coin balance of reciepient ad decerement by one
            totalOwned[msg.sender] += 1;
            // call the event to store the change ownership details in the block
            lovecoin[_coinID].sellPrice=RATE;
            lovecoin[_coinID].sellAvailability= false;
            saleCount--;
            _currentOwner.transfer(msg.value);
            LoveTransfer(_currentOwner,msg.sender,_coinID);
            return true;
        }
        
        function claimLove(uint256 _coinID) public payable returns(bool)  {
                
                require(
                        msg.value == bid[_coinID].bidAmount &&
                        bid[_coinID].bidBy == msg.sender &&
                        bid[_coinID].ApprovalStatus == true  
                        );
                        
                        address currentOwner = lovecoin[_coinID].coinOwner;
                         
                        lovecoin[_coinID].coinOwner = msg.sender;  
                        totalOwned[currentOwner] -= 1;
                        totalOwned[msg.sender] += 1;
                        delete bid[_coinID];
                        currentOwner.transfer(msg.value);
                        LoveTransfer(currentOwner,msg.sender,_coinID);
                        return true;
                        
        }
        
        
        function lovesbyOwner() public constant returns(uint256[])  {
                
                uint256[] memory _coinID = new uint256[](totalOwned[msg.sender]);
                uint8 _index = 0;
                for(uint256 i=1; i<(totalSupply+1);i++) {
        
                        if(lovecoin[i].coinOwner == msg.sender) {
                
                                _coinID[_index] = lovecoin[i].coinID;
                                _index++;
                        }
                }   
                return (_coinID);
        }  
         
        
        function name() public pure returns(string) {
                        return NAME;
        }
 
        function symbol() public pure returns(string) {
                return SYMBOL;
        }
 
        function totalSupply() public constant returns(uint256) {
                return totalSupply;
        }
 
        function balanceOf(address _owner) public constant returns(uint)  {
                return totalOwned[_owner];
        }
 
        function isSoldout() public constant returns (bool) {
 
            return (totalSupply == 50000);
 
        }
 
    
 
        event LoveTransfer(address indexed _owner, address _to, uint256 _coinID);
        event CreateLove(address indexed _owner, uint256 _coinID);
        event Bidding (address indexed _from,uint256 _bidID, uint256 _coinID, uint256 _bidAmount);
        event ApproveBid(address indexed _from, uint256 _bidID, uint256 _coinID, uint256 _bidAmount);
        event Claim(address indexed _from,address _to,uint256 _bidID, uint256 _coinID, uint256 _bidAmount);
        
}
 



