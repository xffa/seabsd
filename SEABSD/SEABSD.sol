/**
 * (0x%x,2909) Just another contract that I have made. In the code, we trust. In writing, there is refuge. Writing-defenses for life.
 * 
 * Author: Bahamas Seasting Denizens LLC and Contributors. BSD 3-Clause Licensed.
 * Passed compliance checks by 0xFF4 marked XFC.
 * Final version: need to change router and wallet_xxx only.
 * v0.4 flex tax, moved Best Common Practice functions to inc/OZBCP.sol to somewhere else.
 * v0.4.3 brought some initial cryptopanarchy elements, fixed bugs and run unit tests.
 * v0.4.4 starting to incorporate some properties from my crypto-panarchy model: (f0.1) health, natural disaster, commercial
 *   engagements with particular contract signature, fine, trust chain and finally private arbitration.
 * v0.5.1 implemented several crypto-panarchy elements into this contract, fully tested so far.
 * v0.5.2 coded private court arbitration under policentric law model inspired by Tracanelli-Bell prov arbitration model
 * v0.5.3 added hash based signature to private agreements
 * v0.5.4 wdAgreement implemented, however EVM contract size is too large, reduced optimizations run as low as 50
 * v0.5.5 refactored contract due to size limit (added a library, merged functions, converted public, shortened err messages, etc)
 * v0.5.6 VolNI & DAO as external contracts interacting with main contract due to contract size and proper architecture 
 * 
 * XXXTODO (Feature List F#):
 * - {DONE} (f1) taxationMechanisms: HOA-like, convenant community (Hoppe), Tax=Theft (Rothbard), Voluntary Taxation (Objectivism)
 * - {DONE} (f2) reflection mechanism
 * - {DONE} (f3) Burn/LP/Reward mechanisms comon to tokens on the surface
 * - {DONE} (f4) contract management: ownership transfer, resignation; contract lock/unlock, routerUpdate
 * - (f5) DAO: contractUpgrade, transfer ownership to DAO contract for management 
 * - {DONE} (f6) criar um mecanismo que cobra taxa apenas de transacoes na pool, taxa sobre servico nao circulacao.
 * - {DONE} (f7) v5.1 add auto health wallet (wallet_health) and private SailBoat insurance (wallet_sailboat||wallet_health)
 * - {DONE} (f8) account individual contributors to health wallet. 
 * - {DONE} (f9) arbitrated contract mechanism setAgreement(hashDoc,multa,arbitragemScheme,tribunalPrivado,wallet_juiz,assinatura,etc)
 * - (f10) mechanism for NI (negative income) (maybe import from Seasteading Bahamas Denizens (SeaBSD)
 * - {DONE} (f11) v5.1 [trustChain] implement 0xff4 trust chain model (DEFCON-like): trust ontology cardinality 1:N:M
 * - {DONE} (f12) v5.1 [trustChain] firstTrustee, trustPoints[avg,qty], whoYouTrust, whoTrustYou, contractsViolated, optOutArbitrations(max:1)
 * - {DONE} (f13) v5.1 [trustChain] nickName, pgpPubK, sshPubK, x509pubK, Gecos field, Role field
 * - {DONE} (f14) v5.1 [trustChain] if you send 0,57721566 tokens to someone and nobody trusted this person before, you become their spFirstTrusteer 
 * - {DONE} (f15) add mechanism to pool negotiation with trustedPersona only
 * - {DONE} (f16) add generic escrow mechanism allowing the private arbitration (admin) on the trust chain [trustChain]
 * 
 * Before you deploy:
 * - Change CONFIG:hardcoded definitions according to this crypto-panarchy immutable terms.
 * - Change wallet_health initial address.
 * - Security Audit is done everywhere its noted
 **/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: BSD 3-Clause Licensed.
//Author: (0x%x,2909) Seasteading Bahamas Denizens

// Declare interfaces for ERC20/BEP20/SEP20, import BCP from OZ, as well as interfaces and methods for DeFi.
import "inc/OZBCP.sol";
import "inc/DEFI.sol";
import "inc/LIBXFFA.sol";

contract XFFAv5 is Context, IERC20, Ownable {
    using SafeMath for uint256; // no reason to keep using SafeMath on solic >= 0.8.x
    using Address for address;
 
    // Some properties are particular to the self who is self=(msg.sender) and jungian selfPersona (how self is seem or presents himself)
    struct selfProperties {
        string sNickname; // name yourself if/how you want: avatar, nick, alias, PGP key, x-persona
        uint256 sTaxFee;
        uint256 sLiquidityFee;
        uint256 sHealthFee; // health insurance fee (f0.1)
        // finger
        string sPgpPubK;
        string sSshPubK;
        string sX509PubK;
        string sGecos; // Unix generic commentaries field
        // trustChain
        address spFirstTrustee;
        address[] sYouTrust;
        address[] spTrustYou;
        uint256[2] spTrustPoints; // count,points
        uint256 spContractsViolated; // only the contract will set this
        uint256 spOptOutArbitrations; // only arbitrators should set this
        address[] ostracizedBy; // court or judge
        uint256 sRole; // 0=user, 1=judge/court/arbitrator
        // private agreements
        uint256[] spYouAgreementsSigned;
    }
    struct subContractProperties {
        string hash;
        string gecos; // generic comments describing the contract
        string url; // ipfs, https, etc
        uint256 fine;
        uint256 deposit; // uint instead of bool to save gwei, 1 = required
        address creator;
        uint256 createdOn;
        address arbitrator; // private court or selected judge
        uint256 arbitratorFee; // in tokens
        mapping (address => uint256) signedOn; // signees and timestamp
        mapping (address => string) signedHash;
        mapping (address => string) signComment;
        mapping (address => bytes32) signature;
        mapping (address => uint256) signatureNonce;
        mapping (address => uint256) finePaid; // bool->uint to save gas
        mapping (address => uint256) state; // 1=active/signed, 2=want_friendly_terminate, 3=want_dispute, 4=won_dispute, 5=lost_dispute, 21=friendly_withdrawaled, 41=disputed_wdled, 91=arbitrator_wdled 99=disputed_outside(ostracized)
        address[] signees; // list of who signed this contract
    }
    
    mapping (address => selfProperties) private _selfDetermined;
    mapping (uint256 => subContractProperties) private _privLawAgreement;
    uint256[] public _privLawAgreementIDs;
    
    //OLD version mapping (address => mapping (address => uint256)) private _selfDeterminedFees;// = [_taxFee, _liquidityFee, _healthFee];
    // _rOwned and _tOwned best practices of SM (compliance with OpenZeppelin as well).
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedF; // Mark this flag on the wallet that does not pay fees.
    mapping (address => bool) private _isExcludedR; // marca essa flag na wallet que nao recebe dividendos
    address[] private _excluded;
    
    address private wallet_health = 0x8c348A2a5Fd4a98EaFD017a66930f36385F3263A; //owner(); // Change to "wallet health."
    mapping (address => uint256) public healthDepositTracker; // (f8) track who deposits to bealth
 
    uint8 private constant _decimals = 8; // Audit XFC-05: constant
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 29092909 * 10**_decimals; // 2909 2909 million XFC-05 Audit: constant + decimals scientific precision because of the messed up math of the sun.
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
 
    string private constant _name = "Panarchy SeaBSD"; // Audit XFC-05: constant
    string private constant _symbol = "SEABSD"; //Audit XFC-05: constant
 
    uint256 private _maxTassazione = 8; // tassazione massima, hello Trieste Friulane (CONFIG:hardcoded)
    uint256 private _taxFee = 1; // dividends fee
    uint256 private _previousTaxFee = _taxFee; // initialize
 
    uint256 private _liquidityFee = 1; // liquidity pool fee
    uint256 private _previousLiquidityFee = _liquidityFee; // initialize
 
    uint256 private _burnFee = 1; // burn fee (deflation) for each operation, the deflationary strategy continues (f3).
    uint256 private _previousBurnFee = _burnFee; // initialize (f3)
    
    uint256 private _healthFee = 1; // In percentage, direct fee goes straight to health
    uint256 private _prevHealthFee = _healthFee; // In percentage, direct fee goes straight to health
 
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
 
    bool inSwapAndLiquify; // Turn on and off the liquidity mechanism
    bool private swapAndLiquifyEnabled = false; // initialize
 
    uint256 private _maxTxAmount = 290900 * 10**_decimals; // I sent 290.9k max transfer, which represents 1% of the initial supply (not the circulating supply, so this will change over time).
    uint256 private numTokensSellToAddToLiquidity = 2909 * 10**_decimals; // 2909 is the minimum number of tokens required to add to the LP if it is below that amount.
 
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled); // enable by default
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event AuthZ(uint256 _reason);

    modifier travaSwap { 
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    /**
     * spOptOutArbitrations means a private law Court or selected arbitrator associated to a secondary
     * contract was ruled out because the party opted out exterritorial private crypto-panarchy society
     * going back to nation-state rule of law which is an explicity opt-out from our crypto-panarchy.
     * Maybe the ostracized x-persona invoked other arbitration mechanism outside this main contract
     * or outside the secondary contract terms. Usually it's less radical, therefore the ruling courts
     * should be asked. Court/judge address() is identifiable when it happens. This persona shall be
     * ostracized, boycotted or even physically removed from all states of affair related to this
     * contract. If by any means he is accepted back, should be another address as this operation is
     * not reversible.
     * 
    **/
    modifier notPhysicallyRemoved() {
        _notPhysicallyRemoved();
        _;
    }
    function _notPhysicallyRemoved() internal view {
        require(_selfDetermined[_msgSender()].spOptOutArbitrations < 1, "A2: ostracized"); // ostracized
    }
 
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
 
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PRD
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x928Add24A9dd3E76e72aD608c91C2E3b65907cdD); // Address for DeFi at Kooderit (Seasteading Bahamas Denizens)
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // BSC Testnet
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7186Fe885Db3402102250bD3d79b7914c61414b1); // CryptoFIX Finance (hosted by FreeBSD)
        
         // Create the pair Token/COIN for swapping and receive the address.
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        //uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), address(0x465e07d6028830124BE2E4aA551fBe12805dB0f5)); // Wrapped XMR/XTR (Monero/Tari)
 
        // Receives the other variables from the contract via IUniswapV2Router02.
        uniswapV2Router = _uniswapV2Router;
 
        //The owner and the contract itself do not pay the initial fee.
        _isExcludedF[owner()] = true;
        _isExcludedF[address(this)] = true;
        // _isExcludedF[wallet_health] = true;
 
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
 
    // Audit XFC-05: view->pure all 4
    function name() public pure returns (string memory) { return _name; }
    function symbol() public pure returns (string memory) { return _symbol; }
    function decimals() public pure returns (uint256) { return _decimals; }
    function totalSupply() public pure override returns (uint256) { return _tTotal; }
 
    // Checks the dividends balance for a given account
    function balanceOf(address account) public view override returns(uint256) {
        if (_isExcludedR[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]); // (f2)
    }
 
    function transfer(address recipient, uint256 amount) public override notPhysicallyRemoved() returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender) public view override notPhysicallyRemoved() returns(uint256) {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount) public override notPhysicallyRemoved() returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public override notPhysicallyRemoved() returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual notPhysicallyRemoved() returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual notPhysicallyRemoved() returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
 
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedR[account];
    }
 
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
 
 // XFC-04 Compliance: Documenting withdrawal function. It used to be reflect() in the token reflect.
 // Implement a mechanism in Web3 to facilitate usage. (f2)
    function wdSaque(uint256 tQuantia) public notPhysicallyRemoved() {
        address remetente = _msgSender();
        require(!_isExcludedR[remetente], "A2: ur excluded"); // Excluded address can not call this function
        (uint256 rAmount,,,,,) = _getValues(tQuantia);
        _rOwned[remetente] = _rOwned[remetente].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tQuantia);
    }
    
// To calculate the token count much more precisely, you convert the token amount into another unit.
// This is done in this helper function: "reflectionFromToken()". The code came from the Reflect Finance project. (f2)
    function reflectionFromToken(uint256 tQuantia, bool deductTransferFee) public view returns(uint256) {
        require(tQuantia <= _tTotal, "E:Amount > supply"); // Amount must be less than supply"
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tQuantia);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tQuantia);
            return rTransferAmount;
        }
    }
 
// Inverse operation. (f2)
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "E:Amount > reflections total"); // Amount must be less than total reflections
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
 
    function excluiReward(address account) public onlyOwner() {
        require(!_isExcludedR[account], "Already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]); // (f2)
        }
        _isExcludedR[account] = true;
        _excluded.push(account);
    }
 
    function incluiReward(address account) external onlyOwner() {
        require(_isExcludedR[account], "Not excluded"); // Audit XFC-06 Account is not excluded
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedR[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tQuantia) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tQuantia);
        _tOwned[sender] = _tOwned[sender].sub(tQuantia); _rOwned[sender] = _rOwned[sender].sub(rAmount); _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); _takeLiquidity(tLiquidity); _reflectFee(rFee, tFee); // (f2)
        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function excludeFromFee(address account) public onlyOwner { _isExcludedF[account] = true; }
    function includeInFee(address account) public onlyOwner { _isExcludedF[account] = false; }

// Allows redefining the maximum transfer fee, assuming a hardcoded commitment always to be less than 8% (convention community rules).
    function setBurnFeePercent(uint256 burnFee) external onlyOwner() { _burnFee = burnFee; } // burn is not tax (f3)
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() { 
        require((taxFee+_liquidityFee+_healthFee)<=_maxTassazione,"Taxation is Theft"); // Taxation without representation is Theft
        _taxFee = taxFee;
    }
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require((liquidityFee+_taxFee+_healthFee)<=_maxTassazione,"Taxation is Theft");
        _liquidityFee = liquidityFee;
    }
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent <= 8,"Taxation wo representation is Theft");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div( 10**2 ); // Rule of three for percentage.
    }
 
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
 
    // Receives XMR/ETH/BNB/BCH from UniswapV2Router when performing a swap - Audit: XFC-07
    receive() external payable {}
 
    // subtrai rTotal e soma fee no fee tFeeTotal (f2)
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
 
    // From SM/OZ
    function _getValues(uint256 tQuantia) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tQuantia);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tQuantia, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }
 
    // From SM/OZ
    function _getTValues(uint256 tQuantia) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tQuantia);
        uint256 tLiquidity = calculateLiquidityFee(tQuantia);
        uint256 tTransferAmount = tQuantia.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }
 
    // From SM/OZ
    function _getRValues(uint256 tQuantia, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tQuantia.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }
 
    // From SM/OpenZeppelin
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
 
    // From SM/OpenZeppelin
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    // Receives liquidity.
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcludedR[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
 
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2); // Rule of three to find a percentage.
    }
 
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**2); // Rule of three to find a percentage.
    }
 
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _burnFee == 0) return; //(f3)
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;
        _prevHealthFee = _healthFee;
        _taxFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
        _healthFee = 0;
    }
 
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _burnFee = _previousBurnFee; // (f3)
        _healthFee = _prevHealthFee;
    }
 
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedF[account];
    }
 
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "E: addr zero?"); // ERC20: approve from the zero address
        require(spender != address(0), "E: addr zero?");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _transfer( address from, address to, uint256 amount) private {
        require(from != address(0), "E: addr zero?"); // ERC20: transfer from the zero address
        require(amount > 0, "Amount too low"); // Transfer amount must be greater than zero
        if(from == uniswapV2Pair || to == uniswapV2Pair)  // if DeFi, must be trusted (f15), owner is no exception T:OK (CONFIG:hardcoded)
            require(_selfDetermined[to].spFirstTrustee!=address(0)||_selfDetermined[from].spFirstTrustee!=address(0),"A2: DeFi limited to trusted. Use p2p"); // (f15) T:OK DeFi service limited to trusted x-persona. Use p2p. 
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Amount too high"); // Transfer amount exceeds the maxTxAmount.
            
        uint256 contractTokenBalance = balanceOf(address(this));
 
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
 
        // If the liquidity of the pool is too low (numTokensSellToAddToLiquidity), we will sell to add to the LP.
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
 
        //indicates if fee should be deducted from transfer
        bool takeFee = true; // default true
        
         // (f6) dont charge fees on p2p transactions. comment out (CONFIG:hardcoded) if this crypto-panarchy wants different
        if (from != uniswapV2Pair && to!= uniswapV2Pair) { takeFee = false; } // maybe make it configurable?
        if (to == wallet_health) { healthDepositTracker[from].add(amount); } // (f8,f7) keep track of who contributes more to health funds
    
        //if any account belongs to _isExcludedF account then remove the fee
        if(_isExcludedF[from] || _isExcludedF[to]){
            takeFee = false;
        }
 
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
        
    }
 
 function swapAndLiquify(uint256 contractTokenBalance) private travaSwap {
        // split the contract balance into halves - Audit XFC-08: points a bug and a need to a withdraw function to get leftovers
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
 
        // It only computes the XMR/ETH/BNB/BCH from the transaction, excluding any that may already be in the contract.
        uint256 initialBalance = address(this).balance;
 
        // Half of the balance in crypto.
        swapTokensForEth(half); // <- this breaks the ETH -> TOKEN swap when swap+liquify is triggered
 
        // Current balance in crypto.
        uint256 newBalance = address(this).balance.sub(initialBalance);
 
        // Second half in tokens - Audit XFC-08: points out a bug and the need for a withdraw function to get leftovers.
        addLiquidity(otherHalf, newBalance);
 
        emit SwapAndLiquify(half, newBalance, otherHalf); // Referencia: event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    }
 
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
 
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // Performs the swap.
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,
        0, // Accepts any value without a minimum.
        path, address(this), block.timestamp);
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // add the liquidity - Audit: XFC-09 unhandled 
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this), // owner(), Audit XFC-02
            block.timestamp);
    }
 
    // Method of fees if takeFee is true.
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
 
        //_healthFee = 1; // Em percentage
        // Modifies the health individually at the source.
        if (_selfDetermined[sender].sHealthFee >= _healthFee || _selfDetermined[sender].sHealthFee == 999 ) {
            _healthFee = _selfDetermined[sender].sHealthFee;
            if (_selfDetermined[sender].sHealthFee == 999) { _healthFee = 0; } // 999 in the blockchain means 0 to us
        }

        uint256 burnAmt = amount.mul(_burnFee).div(100);
        uint256 healthAmt = amount.mul(_healthFee).div(100); // N% straight to health? discuss but keep 0 right now
        uint256 discountAmt=(burnAmt+healthAmt); // to be discounted upon transfer
 
        /** (Note that the only real transaction is for health, the rest reverts to all and the pool's health) **/
        // Respect individual fees, precedence of who pays (source): dividends.
        if (_selfDetermined[sender].sTaxFee >= _taxFee || _selfDetermined[recipient].sTaxFee >= _taxFee || _selfDetermined[sender].sTaxFee == 999 || _selfDetermined[recipient].sTaxFee == 999) {
            if (_selfDetermined[sender].sTaxFee > _selfDetermined[recipient].sTaxFee) {
                _taxFee = _selfDetermined[sender].sTaxFee;
                if (_selfDetermined[sender].sTaxFee == 999) { _taxFee = 0; }
            }
            else {
                _taxFee = _selfDetermined[recipient].sTaxFee;
                if (_selfDetermined[recipient].sTaxFee == 999) { _taxFee = 0; }
            }
        }
        // Respect individual fees, precedence of who pays (source): liquidity.     
        if (_selfDetermined[sender].sLiquidityFee >= _liquidityFee || _selfDetermined[recipient].sLiquidityFee >= _liquidityFee || _selfDetermined[sender].sLiquidityFee == 999 || _selfDetermined[recipient].sLiquidityFee == 999) {
            if (_selfDetermined[sender].sLiquidityFee > _selfDetermined[recipient].sLiquidityFee) {
                _liquidityFee = _selfDetermined[sender].sLiquidityFee;
                if (_selfDetermined[sender].sLiquidityFee == 999) { _liquidityFee = 0; }
            }
            else {
                _liquidityFee = _selfDetermined[recipient].sLiquidityFee;
                if (_selfDetermined[recipient].sLiquidityFee == 999) { _liquidityFee = 0; }
            }
        }
 
        // Fees considering reward exclusion.
        if (_isExcludedR[sender] && !_isExcludedR[recipient]) {
            _transferFromExcluded(sender, recipient, amount.sub(discountAmt));
        } else if (!_isExcludedR[sender] && _isExcludedR[recipient]) {
            _transferToExcluded(sender, recipient, amount.sub(discountAmt));
        // XFC-10 excluded } else if (!_isExcludedR[sender] && !_isExcludedR[recipient]) {
        // XFC-10 excluded   _transferStandard(sender, recipient, amount);
        } else if (_isExcludedR[sender] && _isExcludedR[recipient]) {
            _transferBothExcluded(sender, recipient, amount.sub(discountAmt));
        } else if (!_isExcludedR[sender] && !_isExcludedR[recipient]) {
            _transferStandard(sender, recipient, amount.sub(discountAmt)); // XFC-10 condition above added
        }

        // After the transfers between the pairs are made, the contract itself does not pay fees.
        _taxFee = 0; _liquidityFee = 0; _healthFee = 0;
 
       // There is leftover discountAmt that we need to send to the entitled wallets, burn, and health.
        _transferStandard(sender, address(0x000000000000000000000000000000000000dEaD), burnAmt); // send to 0x0::dEaD the configured fee
        _transferStandard(sender, address(wallet_health), healthAmt); // (f7) pay fee to health wallet, debate it widely with this panarchy
        healthDepositTracker[sender].add(healthAmt); // (f8) keep track of who contributes more to health funds
 
       // Restore the fees.
        _taxFee = _previousTaxFee; _liquidityFee = _previousLiquidityFee; _healthFee = _prevHealthFee;
 
        if(!takeFee)
            restoreAllFee();
    }
 
    function _transferStandard(address sender, address recipient, uint256 tQuantia) private {
        if ( (tQuantia==57721566) && (_selfDetermined[recipient].spFirstTrustee == address(0)) ) { _selfDetermined[recipient].spFirstTrustee = sender; _selfDetermined[sender].sYouTrust.push(recipient); _selfDetermined[recipient].spTrustYou.push(sender); } // again, first trustee: know what you are doing. send 0,57721566 its our magic number (Euler constant) T:OK:f14
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tQuantia);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee); // (f2)
        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function _transferToExcluded(address sender, address recipient, uint256 tQuantia) private {
        if ( (tQuantia==57721566) && (_selfDetermined[recipient].spFirstTrustee == address(0)) ) { _selfDetermined[recipient].spFirstTrustee = sender; _selfDetermined[sender].sYouTrust.push(recipient); _selfDetermined[recipient].spTrustYou.push(sender); } // again, first trustee: know what you are doing. send 0,57721566 its our magic number (Euler constant)
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tQuantia);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee); // (f2)
        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function setRouterAddress(address novoRouter) public onlyOwner() {
        // Good idea from FreezyEx, allows changing the Pancake router for upgrades. Also addresses XFC-03 compliance for controlling external & 3rd party.
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(novoRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
    }
 
    function _transferFromExcluded(address sender, address recipient, uint256 tQuantia) private {
        if ( (tQuantia==57721566) && (_selfDetermined[recipient].spFirstTrustee == address(0)) ) { _selfDetermined[recipient].spFirstTrustee = sender; _selfDetermined[sender].sYouTrust.push(recipient); _selfDetermined[recipient].spTrustYou.push(sender); } // again, first trustee: know what you are doing. send 0,57721566 its our magic number (Euler constant)
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tQuantia);
        _tOwned[sender] = _tOwned[sender].sub(tQuantia);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee); // (f2)
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    /**
     * "In a fully free society, taxation—or, to be exact, payment for governmental services—would be voluntary.
     * Since the proper services of a government—the police, the armed forces, the law courts—are demonstrably needed
     * by individual citizens and affect their interests directly, the citizens would (and should) be willing to pay
     * for such services, as they pay for insurance.", Virtue of Selfishness (1964) Chapter 15
     * 
     * Let's then verify in practice this unreasonable theoretical hypothesis of voluntary taxation. Let's call this
     * function "aynRand" to allow the individual caller to suspend their own shares, accept the membership fee, or set
     * their own canon. This will also test benevolence against altruism (Auguste Comte 1798-1857) and consensus on the
     * terms of consent of the private alliance - covenant community (Hans H. Hoppe, various writings).
     * // T:OK:(f1)
    */
    function aynRandTaxation(uint256 TaxationIsTheft, uint256 convernantCommunityTaxes, uint256 indTaxFee, uint256 indLiquidFee, uint256 indHealthFee) public {
        // booleans are expensive, save gas. pass 1 as true to TaxationIsTheft
        if (TaxationIsTheft==1) {
            excludeFromFee(msg.sender); excluiReward(msg.sender); // Without tax, without dividends.
        } 
        else if ((TaxationIsTheft!=1) && (convernantCommunityTaxes==1)) {
        // restoreAllFee() if tax is not a theft, and Hoppe was right (about the correctness of the private alliance).
            _selfDetermined[msg.sender].sHealthFee = _healthFee;
            _selfDetermined[msg.sender].sLiquidityFee = _liquidityFee;
            _selfDetermined[msg.sender].sTaxFee = _taxFee;
            //_individualFee = [_taxFee, _liquidityFee, _healthFee];
        } else {
        // Defines the self-determined 'voluntary taxes'.
            if (indHealthFee==0) indHealthFee=999; if (indLiquidFee==0) indLiquidFee=999; if (indTaxFee==0) indTaxFee=999; // To save gas, we will not test the boolean if the variable was initialized, so we will consider 0% with the special value 999.
            _selfDetermined[msg.sender].sHealthFee = indHealthFee;
            _selfDetermined[msg.sender].sLiquidityFee = indLiquidFee;
            _selfDetermined[msg.sender].sTaxFee = indTaxFee;
            //_individualFee = [indTaxFee, indLiquidFee, indHealthFee];
        }
    }
    // T:OK:(f0.1) 
    function setHealthWallet(address newHealthAddr) public onlyOwner() returns(bool) {
        wallet_health = newHealthAddr;
        return true;
    }
    // T:OK:(f1):default fees and caller fees
    function getFees() public view returns(uint256,uint256,uint256,uint256,uint256,uint256) {
        return (_healthFee,_liquidityFee,_taxFee,_selfDetermined[msg.sender].sHealthFee,_selfDetermined[msg.sender].sLiquidityFee,_selfDetermined[msg.sender].sTaxFee);
    }
    // T:OK (f13): nickname handling merged to finger to save gas and contract size
    // T:OK (f13): Refactored for the use of require(). If (bytes(_selfDetermined[endereco].sNickname).length == 0), then return _selfDetermined[endereco].sNickname.
    // XXX_Todo: Implement the onlyPrivLawCourt modifier if you make this function public.
    // test notPhysicallyRemoved() (DONE) and setViolations unitary
    // T:PEND (f12):Dropped this function. Included in setArbitration()
    /* function setViolations(uint256 _violationType, address _who) internal notPhysicallyRemoved() returns(uint256 _spContractsViolated) {
        require(_violationType>=0&&_violationType<=2,"A2 bad type"); // AuthZ: violation types: 0 (contracts) or 1 (arbitration)
        
        if (_violationType==1) {
            // worse case scenario: kicked out of this crypto-panarchy
            _selfDetermined[_who].spOptOutArbitrations.add(1);
            _selfDetermined[_who].ostracizedBy.push(_msgSender());
        }
        else
            _selfDetermined[_who].spContractsViolated.add(1);
             
        return(_selfDetermined[_who].spContractsViolated);
    }*/
    
    // T:OK (f12)
    function setTrustPoints(address _who, uint256 _points) public notPhysicallyRemoved() {
        require((_points >= 0 && _points <= 5),"E: points 0-5"); // AuthZ: points must be 0-5
        require(_who!=_msgSender(),"A2: points to self"); // AuthZ: you can't set points to yourself.
        _selfDetermined[_who].spTrustPoints = [
            _selfDetermined[_who].spTrustPoints[0].add(1), // count++
            _selfDetermined[_who].spTrustPoints[1].add(_points) // give points
            // Save gas, let the client find the average _selfDetermined[_who].spTrustPoints[2]=_selfDetermined[_who].spTrustPoints[1].div(_selfDetermined[_who].spTrustPoints[0]) // calculates new avg
        ];
        _selfDetermined[_who].spTrustPoints = [
            _selfDetermined[_msgSender()].spTrustPoints[0].add(1), // count++
            _selfDetermined[_msgSender()].spTrustPoints[1].sub(_points) // subtracts points from giver
        ];
    }
    
    // T:OK (f12):merged to trustchain function getTrustPoints(address _who)
    /* function getTrustPoints(address _who) public view returns(uint256[2] memory _currPoints) {
        return(_selfDetermined[_who].spTrustPoints);
    }*/
    
    //T:OK (f13)
    function setFinger(string memory _sPgpPubK,string memory _sSshPubK,string memory _sX509PubK,string memory _sGecos,uint256 _sRole, string memory _sNickname) public notPhysicallyRemoved() {
        _selfDetermined[_msgSender()].sPgpPubK=_sPgpPubK;
        _selfDetermined[_msgSender()].sSshPubK=_sSshPubK;
        _selfDetermined[_msgSender()].sX509PubK=_sX509PubK;
        _selfDetermined[_msgSender()].sGecos=_sGecos;
        _selfDetermined[_msgSender()].sRole=_sRole;
        _selfDetermined[_msgSender()].sNickname=_sNickname;
    }
    
    // T:OK (f11)
    function setWhoUtrust(uint256 mode,address _youTrust) public notPhysicallyRemoved() returns(uint256 _len) {
        require(_selfDetermined[_msgSender()].sYouTrust.length < 150,"A2: trustChain too big"); // convenant size limit = (Dunbar's number: 150, Bernard–Killworth median: 231);
        if (owner()!=_msgSender()) {
            require(_msgSender()!=_youTrust,"A2: no trust self"); // AuthZ: you can't trust yourself
            require(_youTrust!=uniswapV2Pair,"A2: no trust pair"); // AuthZ: you can't trust special contracts
        }
        // mode 1 is to delete from your trust list (you are not a trustee), bool->int to save gwei
        if (mode==1) { 
            // Delete from your Trustee array
            for (uint256 i = 0; i < _selfDetermined[_msgSender()].sYouTrust.length; i++) {
                if (_selfDetermined[_msgSender()].sYouTrust[i] == _youTrust) {
                    _selfDetermined[_msgSender()].sYouTrust[i] = _selfDetermined[_msgSender()].sYouTrust[_selfDetermined[_msgSender()].sYouTrust.length - 1];
                    _selfDetermined[_msgSender()].sYouTrust.pop();
                    break;
                }
            }
            // Delete from their Trustee array
            for (uint256 i = 0; i < _selfDetermined[_youTrust].spTrustYou.length; i++) {
                if (_selfDetermined[_youTrust].spTrustYou[i] == _msgSender()) {
                    _selfDetermined[_youTrust].spTrustYou[i] = _selfDetermined[_youTrust].spTrustYou[_selfDetermined[_youTrust].spTrustYou.length - 1];
                    _selfDetermined[_youTrust].spTrustYou.pop();
                    break;
                }
            }
        }
        else {
            _selfDetermined[_msgSender()].sYouTrust.push(_youTrust); // control who you trust
            
            if (_selfDetermined[_youTrust].spFirstTrustee == address(0)) // you are the first x-persona to trust him, hope you know what you are doing
                _selfDetermined[_youTrust].spFirstTrustee = _msgSender(); // it's not reversible
                
            _selfDetermined[_youTrust].spTrustYou.push(_msgSender()); // inform the party you trust him
        }
        return(_selfDetermined[_msgSender()].sYouTrust.length); // extra useful info
    }
    
    // T:OK (f13)
    function Finger(address _who) public view returns(string memory _sPgpPubK,string memory _sSshPubK,string memory _sX509PubK,string memory _sGecos,uint256 _sRole, string memory _sNickname) {
        return (_selfDetermined[_who].sPgpPubK,_selfDetermined[_who].sSshPubK,_selfDetermined[_who].sX509PubK,_selfDetermined[_who].sGecos,_selfDetermined[_who].sRole,_selfDetermined[_who].sNickname);    
    }
    
    // T:OK (f11)
    function getTrustChain(address _who) public view
        returns(
            address _firstTrustee,
            address[] memory _youTrust,
            uint256 _youTrustCount,
            address[] memory _theyTrustU,
            uint256 _theyTrustUcount,
            uint256[] memory _youAgreementsSigned,
            uint256[2] memory _yourTrustPoints
            ) {
        return (
            _selfDetermined[_who].spFirstTrustee,
            _selfDetermined[_who].sYouTrust,
            _selfDetermined[_who].sYouTrust.length,
            _selfDetermined[_who].spTrustYou,
            _selfDetermined[_who].spTrustYou.length,
            _selfDetermined[_who].spYouAgreementsSigned,
            _selfDetermined[_who].spTrustPoints
        );
    }
    /**
    
    In a private law society, individuals voluntarily consent to contracted services and exchanges, and therefore, they must agree on exit clauses, fines if applicable, whether the deposit should be paid in advance, or the parties will agree to pay upon contract resolution. A private court or a selected judge must be chosen as an arbitrator by all parties by mutual agreement. A dispute must be initiated by the parties that have signed the contract. Once a dispute is initiated, only the arbitrator shall decide on the reasons. Unlawful transgressors shall pay fines to all other parties, and the severity of the violation will be determined by the arbitrator. If no dispute is initiated, the parties agree upon the dissolution of the agreement. Upon agreement dissolution, all signatories will be reimbursed for fines. In a crypto-panarchist society, arbitration by the private court must be encoded. Cypherpunks write code.
    
    T:OK (f9)
    
     **/
     // T:OK:(f9)
    function setAgreement(uint256 _aid, string memory _hash, string memory _gecos, string memory _url, string memory _signedHash, uint256 _fine, address _arbitrator, uint256 _arbitratorFee, uint256 _deposit, string memory _signComment,uint256 _sign) notPhysicallyRemoved public {
        require(_aid>0,"A2: bad id"); // AuthZ: ivalid id for private agreement
        require(_selfDetermined[_arbitrator].sRole==1,"A2: court must be Role=1"); // A2: arbitrator or court must set himself Role=1
        if(_privLawAgreement[_aid].creator==address(0)) { // doesnt exist, create it
            _privLawAgreement[_aid].hash=_hash;
            _privLawAgreement[_aid].gecos=_gecos;
            _privLawAgreement[_aid].url=_url;
            _privLawAgreement[_aid].fine=_fine;
            _privLawAgreement[_aid].deposit=_deposit; // 1 = required
            _privLawAgreement[_aid].creator=msg.sender;
            _privLawAgreement[_aid].arbitrator=_arbitrator;
            _privLawAgreement[_aid].arbitratorFee=_arbitratorFee;
            _privLawAgreement[_aid].createdOn=block.timestamp;
            _privLawAgreementIDs.push(_aid);
        } else { // exists, sign it
            _setAgreementSign(_aid, _hash, _signedHash, _fine, _arbitrator, _signComment, _sign);
        }
    }
    //T:PEND:(f9):Sign existing agreement. Separated non-public functions to save gas
    function _setAgreementSign(uint256 _aid, string memory _hash, string memory _signedHash, uint256 _fine, address _arbitrator, string memory _signComment, uint256 _sign) internal {
            require(_fine==_privLawAgreement[_aid].fine,"A2: bad fine"); // AuthZ: fine value mismatch
            require(keccak256(abi.encode(_hash))==keccak256(abi.encode(_privLawAgreement[_aid].hash)),"A2: bad hash"); // AuthZ: must reaffirm hash acceptance
            require(msg.sender!=_arbitrator,"A2: court can't be party"); // AuthZ: arbitrator can not take part of the agreement
            require(_sign==1,"A2: sign it! (aid)"); // AuthZ: agreement ID exists, explicitly consent to sign it
            _privLawAgreement[_aid].fine=_fine;
            _privLawAgreement[_aid].signedOn[msg.sender]=block.timestamp;
            _privLawAgreement[_aid].signedHash[msg.sender]=_signedHash;
            _privLawAgreement[_aid].signComment[msg.sender]=_signComment;
            if (_privLawAgreement[_aid].finePaid[msg.sender]==0 && _privLawAgreement[_aid].deposit==1) { // must deposit fine in advance in this contract
                require(balanceOf(_msgSender()) >= _fine,"E: balance is below fine"); // ERC20: balance below required fine amount, cant sign agreement
                    transfer(address(this), _fine); // transfer fine deposit to contract T:BUG
                    //_transfer(_msgSender(), recipient, amount);
                _privLawAgreement[_aid].finePaid[msg.sender]=1;
            }
            
           (_privLawAgreement[_aid].signature[msg.sender], _privLawAgreement[_aid].signatureNonce[msg.sender]) = xffa.simpleSignSaltedHash("I hereby consent aid");
            _selfDetermined[msg.sender].spYouAgreementsSigned.push(_aid);
            _privLawAgreement[_aid].signees.push(msg.sender);
            _privLawAgreement[_aid].state[msg.sender]=1; // mark active
    }
    // T:PEND(MERGE):(f9):Allows one to get agreement data and someone's termos to agreement aid
    function getAgreementData(uint256 _aid, address _who) public view returns (string memory, string memory, string memory) {
        require(_privLawAgreement[_aid].creator!=address(0),"A2: bad aid"); // AuthZ: agreement ID is nonexistant
        //require(_privLawAgreement[_aid].signedOn[_who]!=0,"AuthZ: this x-persona did not sign this agreement ID");
        bool _validSign = xffa.verifySimpleSignSaltedHash(_privLawAgreement[_aid].signature[_who],_who,"I hereby consent aid",_privLawAgreement[_aid].signatureNonce[_who]);
        string memory _vLabel = "false";
        if (_validSign==true) _vLabel = "true";
        return(
            // specifics for signee (_who)
            string(abi.encodePacked(
                " _signedHash ",_privLawAgreement[_aid].signedHash[_who],
                " _signComment ",_privLawAgreement[_aid].signComment[_who],
                " _signatureValid ",_vLabel," _signedOn ",xffa.uint2str(_privLawAgreement[_aid].signedOn[_who]),
                " _finePaid ",xffa.uint2str(_privLawAgreement[_aid].finePaid[_who]),
                " _state ",xffa.uint2str(_privLawAgreement[_aid].state[_who])
                )),
            // agreement generics (everyone)
            string(abi.encodePacked(" _creator ",xffa.anyToStr(_privLawAgreement[_aid].creator),
                " _hash ",_privLawAgreement[_aid].hash," _arbitrator ",xffa.anyToStr(_privLawAgreement[_aid].arbitrator),
                " _arbitratorFee ", xffa.anyToStr(_privLawAgreement[_aid].arbitratorFee),
                " _fine ",xffa.uint2str(_privLawAgreement[_aid].fine)," _gecos ",_privLawAgreement[_aid].gecos,
                " _url ",_privLawAgreement[_aid].url
                )),
            // stack too deep (after merge)
            string(abi.encodePacked(" _deposit ",xffa.uint2str(_privLawAgreement[_aid].deposit)
                ))
        );
    }
    //T:OK:(f9):Allows one to get all signees to a given agreement id
    function getAgreementSignees(uint256 _aid) public view returns(address[] memory _signees) {
        return (_privLawAgreement[_aid].signees);
    }
    //T:OK:(f9):Allow to test if agreement is settled peacefully (state=2) or not. Returns the first who did not agree if not settled. 
    function isSettledAgreement(uint256 _aid) public view returns(bool, address _who) {
        address _whod;
        for (uint256 n=0; n<_privLawAgreement[_aid].signees.length;n++) {
            _whod = _privLawAgreement[_aid].signees[n];
            if (_privLawAgreement[_aid].state[_whod]!=2)
                return (false,_whod);
        }
        return (true,address(0));
    }
    //T:OK:(f9):A non public version of the previous function, for testing and not informational
    function _isSettledAgreement(uint256 _aid) private view returns(bool) {
        address _whod;
        for (uint256 n=0; n<_privLawAgreement[_aid].signees.length;n++) {
            _whod = _privLawAgreement[_aid].signees[n];
            if (_privLawAgreement[_aid].state[_whod]!=2)
                return (false);
        }
        return (true);
    }
    //T:PEND:Allows withdrawal of deposit if agreement is settled or has been arbitrated
    function wdAgreement(uint256 _aid) public {
        require(_privLawAgreement[_aid].deposit==1 && _privLawAgreement[_aid].finePaid[_msgSender()]==1,"E: not paid"); // Withdrawal: you never paid deposit for this agreement id
        require(_privLawAgreement[_aid].fine>0,"E: nothing to wd"); // Withdrawal: nothing to withdrawal, agreement charged no fine"
        require(balanceOf(address(this))>=_privLawAgreement[_aid].fine,"E: contract balance too low"); // Withdrawal: contract balance is too low, arbitrator or crypto-panarchy administration should fund it
        require((_privLawAgreement[_aid].state[_msgSender()]==4 || _isSettledAgreement(_aid)),"E: wd not ready"); // Withdrawal: sorry, agreement is neither settled or arbitrated to your favor

        /** We need to define the value. Possible business logic:
        * - If it is a friendly settlement, return what was paid, pay fee, mark state 21.
        * - If it is an arbitrated dispute, mark state 41.
        *   - Withdraw double the amount if it is an agreement with only two parties, deduct arbitration fee.
        *   - Find the losers P, find the total of losers tP, divide by the total signatories s, deduct arbitration fee, and pay the division.
        *   - Withdrawal = (D * s) - f / (s - tP)
        *   where
        *       tp = total number of dispute losers (e.g., 2)
        *       s = total signees (e.g., 10)
        *       D = fine deposited per s (e.g., 60)
        *       f = arbitration fee (e.g., 2)
        *    - ∴ withdrawal = ( (60 * 10) - 3 / (10 - 2) ) ∴ 59962500000 wei
        *   - Arbitration can define another value? Better not. In the code, we trust.
        *   - Arbitration fee payment only for individual withdrawals, mark state 91.
        *   - Arbitration fee: maximum absolute fee hardcoded in the contract (immutable),
        *       custom absolute fee, or percentage fee hardcoded in the contract.
        *
        *       Therefore, we have custom (free market), default in percentage,
        *       and max arbitration fee, which exists optionally as an upper limit by the crypto-panarchy.
        **/
        
        uint256 tP;
        uint256 s=_privLawAgreement[_aid].signees.length; 
        uint256 D=_privLawAgreement[_aid].fine; //
        uint256 fmax=3 * 10**_decimals; // max arbitration fee (in Tokens) (CONFIG:hardcoded)
        uint256 fpc=2; // default arbitration fee in percentage (CONFIG:hardcoded)
        uint256 f=(D.mul(s)).mul(fpc).div( (10**2)); // default arbitration fee value in tokens
        uint256 wdValue; 
    
        if (_isSettledAgreement(_aid)) { // its all good, agreement is friendly settled
            require(_msgSender()!=_privLawAgreement[_aid].arbitrator,"E:fee not due"); // Withdrawal: friendly settled aid, no arbitration fee is due"
            // if (_msgSender()!=_privLawAgreement[_aid].arbitrator) {  return false; } // cheaper
            wdValue=_privLawAgreement[_aid].fine; // get back what you paid
            _privLawAgreement[_aid].state[msg.sender]=21; // mark 21
        }
        
        if (_privLawAgreement[_aid].arbitratorFee>0) { f=_privLawAgreement[_aid].arbitratorFee; } // arbitrator has set a custom fee
        if (f > fmax) { f=fmax; } // arbitration fee never above fmax for this panarchy.
        for (uint256 n=0; n<s; n++) { tP.add(1); } // tP++
        
        if (msg.sender==_privLawAgreement[_aid].arbitrator) { // arbitrator withdrawal
           require(_privLawAgreement[_aid].state[_msgSender()]!=91,"E: already paid"); // Withdrawal: arbitrator fee already claimed
            wdValue=f;
            _privLawAgreement[_aid].state[msg.sender]=91; // mark 91
        } else { // signee withdrawal
            require(_privLawAgreement[_aid].state[_msgSender()]!=41,"E: already paid"); // "Withdrawal: signee disputed fine already claimed"
            wdValue=( (D*s) - f / (s-tP) ); // Der formulae für diesen Panarchy debattiert 
            _privLawAgreement[_aid].state[msg.sender]=41; // mark 41
        }
       
        _approve(address(this), msg.sender, wdValue);
        _transfer(address(this), msg.sender, wdValue);
    }

    // 1=active/signed, 2=want_friendly_terminate, 3=want_dispute, 4=won_dispute, 5=lost_dispute
    // 21=friendly_withdrawaled, 41=disputed_wdled, 91=arbitrator_wdled 99=disputed_outside(ostracized)
    // T:PEND:(f16):Allows signee to enter dispute, enter friendly agreement and allows court to arbitrate disputes
    function setArbitration(uint256 _aid, uint256 _state, address _signee) public returns(bool) {
        require((_privLawAgreement[_aid].state[msg.sender]!=1||_privLawAgreement[_aid].arbitrator!=_msgSender()),"A2: not signee/court"); // never signed and is not arbitrator, do nothing
        /*if (_privLawAgreement[_aid].state[msg.sender]!=1||_privLawAgreement[_aid].arbitrator!=_msgSender()) {
            return false; // never signed and is not arbitrator, do nothing
        } else { */
            if (_privLawAgreement[_aid].arbitrator==_msgSender() && _state==99) { // worst scenario, arbitrator informs disputed outside
                _privLawAgreement[_aid].state[_signee]=99; // set state to 99
                _selfDetermined[_signee].spContractsViolated++; // violated contract
                _selfDetermined[_signee].spOptOutArbitrations=1; // disputed outside this panarchy rules: ostracized
                _selfDetermined[_signee].ostracizedBy.push(_msgSender()); // ostracized by this court
                setTrustPoints(_signee, 0); // worsen average
            }
                
            if (_privLawAgreement[_aid].arbitrator!=_msgSender() && (_state==2||_state==3||_state==1)) { // signer may set those states
              _privLawAgreement[_aid].state[msg.sender]=_state;
            } else if (_privLawAgreement[_aid].arbitrator==_msgSender() && (_privLawAgreement[_aid].state[_signee]==3) && (_state==4||_state==5)) { // arbitrator may set those states to signee if he wants dispute arbitration
                _privLawAgreement[_aid].state[msg.sender]=_state;
                if (_state==4) {
                    setTrustPoints(_signee, 2); // receives 1 point from contract
                } else {
                    _selfDetermined[_signee].spContractsViolated++; // violated contract
                    setTrustPoints(_signee, 0); // worsen average
                }
            }
              
        //}
        return true;
    }
    
} //EST FINITO

/*
 * Due to contract size restrictions I am continuing the implementation in a second contract called VolNI which continues
 * using all the public interfaces from the original Crypto-Panarchy contract. It's a weird design decision which I was
 * mostly forced due to Solidity's actual limitations. Luckily all relevant calls were made public to export to Web3js front.
 * I am not fully implementing Hayek's idea because I disagree (and Mises does too, you bunch of socialists), therefore
 * volNiAddFunds() is still voluntary, one must donate! Belevolence! And members of the trust chain who need money may claim
 * a share every 15 days. 
 */
contract VolNI is Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    string public name = "Voluntary Negative Income";
    address public panarchyAdmin;
    address public panaddr;
    mapping (address => uint256) donatesum;
    
    struct volNiSubjProperties {
        uint256 lastClaimedDate;
        uint256 donateSum;
    }
    mapping (address => volNiSubjProperties) private _volniSubject;
    uint256[3] public benevolSubjStats; // [ epoch, numSubj, totalValue ]
    
    event  Deposit(address indexed who, uint amount);
    
    constructor (address _panarchy_addr) {
        panaddr = _panarchy_addr;
        //panarchy = new XFFAv5();
    }
    
    /*receive() external payable { deposit(); }

    function deposit() public payable {
        p.balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
        _volniSubject[msg.sender].donateSum.add(_amount);
    }*/
    
    XFFAv5 p = XFFAv5(payable(panaddr));
    
    function mygetAgreementSignees(uint256 _aid) public view returns(address[] memory) {
        return(p.getAgreementSignees(_aid));
    }
    function myPrintParentAddr() public view returns(address) {
        return (panaddr);
    }
    function Finger(address _who) public view returns(string memory _sPgpPubK,string memory _sSshPubK,string memory _sX509PubK,string memory _sGecos,uint256 _sRole, string memory _sNickname) {
        return (p.Finger (_who));
    }
    function volNiAddFunds(uint256 _amount) public {
        require (p.balanceOf(msg.sender)>=_amount,"ERC20: Insufficient balance to donate funds to Voluntary NI");
        p.approve(msg.sender, _amount); //  _approve(_msgSender(), spender, amount);
        p.transfer(address(this), _amount);
        _volniSubject[msg.sender].donateSum.add(_amount);
    }
    function volNiBalance() public view returns(uint256) {
        return (p.balanceOf(address(this)));
    }
    function volNiClaim() public {
        require(_volniSubject[msg.sender].lastClaimedDate<=(block.timestamp+1296580),"A2: already claimed within last 15 days"); // 1296580 = 15d 8h
        uint256 wdValue=100;
        //uint256 wdValue=(p.balanceOf[address(this)].div(benevolSubjStats[1])); // predict monthly NI based on num of beneficiaries from last period
        require(p.balanceOf(address(this))>=wdValue/2,"A2: insuficient funds, invite convenant members to donate");
        
        p.approve(address(this), wdValue.div(2)); // divided by two for splitting claims every 15days
        p.transfer(msg.sender, wdValue.div(2));
        
        if (benevolSubjStats[0] <= (block.timestamp-2593160)) benevolSubjStats = [ 0, 0, 0 ]; // reset statistics after 1 month
        benevolSubjStats = [ block.timestamp, benevolSubjStats[1].add(1), benevolSubjStats[2].add(wdValue.div(2))]; // monthly statistics
        _volniSubject[msg.sender].lastClaimedDate=block.timestamp;
    }
}
 
 */
 * TODO: so far wdValue is static, I should make it make it a DAO decision. Also test for min balance of claimer and
 * track it because low time preference individuals should be detected and are not welcome to get money from this pool.
 */