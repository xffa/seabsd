/**
 * (0x%x,2909) Solo une altro contratta che ho fatto. Nel codice ci fidiame. In crito e rifugio. Crito-difese à vita.
 * 
 * Author: (0x%x,2909) 2021 Crypto Fix Finance and Contributors. BSD 3-Clause Licensed. Migrated from SeaBSD's Tari/Rust to Solidity
 * Baseate ni Putanas.
 * Passed compliance checks by 0xFF4 marked XFC.
 * Final version: need to change router and wallet_xxx only.
 * v0.4 flex tax, moved Best Common Practice functions to inc/OZBCP.sol to somewhere else.
 * v0.4.3 brought some initial cryptopanarchy elements, fixed bugs and run unit tests.
 * v0.4.4 starting to incorporate some properties from my crypto-panarchy model: (f0.1) health, natural disaster, commercial
 *   engagements with particular contract signature, fine, trust chain and finally private arbitration.
 * v0.5.1 implemented several crypto-panarchy elements into this contract, fully tested so far.
 * v0.5.2 coded private court arbitration under policentric law model inspired by Tracanelli-Bell prov arbitration model
 * 
 * XXXTODO (Feature List F#):
 * - {DONE} (f1) taxationMechanisms: HOA-like, convenant community (Hoppe), Tax=Theft (Rothbard), Voluntary Taxation (Objectivism)
 * - {DONE} (f2) reflection mechanism
 * - {DONE} (f3) Burn/LP/Reward mechanisms comon to tokens on the surface
 * - {DONE} (f4) contract management: ownership transfer, resignation; contract lock/unlock, routerUpdate
 * - DAO: contractUpgrade, transfer ownership to DAO contract for management 
 * - {DONE} (f6) creare un meccanismo che addebita una commissione solo per le transazioni in piscina, una commissione sul servizio di non circolazione.
 * - {DONE} (f7) v5.1 portafoglio di assicurazioni sanitarie con collaborazione automatica (portafoglio sanitario) e assicurazioni di proprietà private/barca a vela 
 * - {DONE} (f8) quantificar recolhimentos individuais para essa wallet saude. 
 * - {DONE} (f9) meccanismo contrattuale arbitrato setAgreement(hashDoc,multa,arbitragemScheme,tribunalPrivado,wallet_juiz,assinatura,etc)
 * - meccanismo di imposta sul reddito negativo (maybe import from SeaBSD)
 * - {DONE} (f11) v5.1 [trustChain] implementar modelo 0xff4 (DEFCON-like): ontologia da confianca 1:N:M
 * - {DONE} (f12) v5.1 [trustChain] firstTrustee, trustPoints[avg,qty], whoYouTrust, whoTrustYou, contractsViolated, optOutArbitrations(max:1)
 * - {DONE} (f13) v5.1 [trustChain] nickName, pgpPubK, sshPubK, x509pubK, Gecos field, Role field
 * - {DONE} (f14) v5.1 [trustChain] if you send 0,57721566 tokens to someone and nobody trusted this person before, you become their spFirstTrusteer 
 * - {FATTO} (f15) crea un meccanismo per consentire al Pool di negoziare solo con persone fidate
 * - {FATTO} (f16) crea un meccanismo di deposito a garanzia generico e consente all'amministratore di arbitrare un contratto arbit
 * 
 * Before you deploy:
 * - Change CONFIG:hardcoded definitions according to this crypto-panarchy immutable terms.
 * - Change wallet_health initial address.
 **/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: BSD 3-Clause Licensed. Author: (0x%x,2909) Crypto Fix Finance 

// Declara interfaces do ERC20/BEP20/SEP20 importa BCP do OZ e tbm interfaces e metodos da DeFi
import "inc/OZBCP.sol";
import "inc/DEFI.sol";
 
contract SEABSDv5 is Context, IERC20, Ownable {
    using SafeMath for uint256; // no reason to keep using SafeMath on solic >= 0.8.x
    using Address for address;
 
    // Algumas propriedades particulares ao self=(msg.sender) e selfPersona (how self is seem or presents himself)
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
        string url; // 
        uint256 fine;
        uint256 deposit; // uint instead of bool to save gwei, 1 = required
        address creator;
        uint256 createdOn;
        address arbitrator; // private court or selected judge
        mapping (address => uint256) signedOn; // signees and timestamp
        mapping (address => string) signedHash;
        mapping (address => string) signComment;
        mapping (address => uint256) finePaid; // bool->uint to save gas
        mapping (address => uint256) state; // 1=active/signed, 2=want_friendly_terminate, 3=want_dispute, 4=won_dispute, 5=lost_dispute, 21=friendly_withdrawaled, 41=disputed_wdled 99=disputed_outside(ostracized)
        address[] signees; // list of who signed this contract
    }
    
    mapping (address => selfProperties) private _selfDetermined;
    mapping (uint256 => subContractProperties) public _privLawAgreement;
    uint256[] private _privLawAgreementIDs;
    
    //OLD version mapping (address => mapping (address => uint256)) private _selfDeterminedFees;// = [_taxFee, _liquidityFee, _healthFee];
    // _rOwned e _tOwned melhores praticas do SM (conformidade com OpenZeppelin tbm)
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedF; // marca essa flag na wallet que nao paga fee
    mapping (address => bool) private _isExcludedR; // marca essa flag na wallet que nao recebe dividendos
    address[] private _excluded;
    
    address public wallet_health = 0x8c348A2a5Fd4a98EaFD017a66930f36385F3263A; //owner(); // Mudar para wallet health
 
    uint256 private constant _decimals = 8; // Auditoria XFC-05: constante
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 29092909 * 10**_decimals; // 2909 2909 milhoes Auditoria XFC-05: constante + decimals precisao cientifica pq das matematicas zoadas do sol
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
 
    string private constant _name = "Coin 0xFF4"; // Auditoria XFC-05: constante
    string private constant _symbol = "SEABSD"; //Auditoria XFC-05: constante
 
    uint256 private _maxTassazione = 8; // tassazione mass hello Trieste Friulane (CONFIG:hardcoded)
    uint256 public _taxFee = 1; // taxa pra dividendos
    uint256 private _previousTaxFee = _taxFee; // inicializa
 
    uint256 public _liquidityFee = 1; // taxa pra LP
    uint256 private _previousLiquidityFee = _liquidityFee; // inicializa
 
    uint256 public _burnFee = 1; // taxa de burn (deflacao) por operacao estrategia de deflacao continua (f3)
    uint256 private _previousBurnFee = _burnFee; // inicializa (f3)
    
    uint256 public _healthFee = 1; // Em porcentagem, fee direto pra health
    uint256 public _prevHealthFee = _healthFee; // Em porcentagem, fee direto pra health
    
    uint256[] private _individualFee = [_taxFee, _liquidityFee, _healthFee];
 
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
 
    bool inSwapAndLiquify; // liga e desliga o mecanismo de liquidez
    bool public swapAndLiquifyEnabled = false; // inicializa
 
    uint256 public _maxTxAmount = 290900 * 10**_decimals; // mandei 290.9k max transfer que da 1% do supply inicial (nao do circulante, logo isso muda com o tempo)
    uint256 private numTokensSellToAddToLiquidity = 2909 * 10**_decimals; // 2909 minimo de tokens pra adicionar na LP se estiver abaixo
 
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled); // liga
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

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
        require(_selfDetermined[_msgSender()].spOptOutArbitrations < 1, "AuthZ: ostracized");
        _;
    }
 
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
 
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PRD
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x133tc9E25852199A0904c978204d4c0A316607e6e747); // Endereco da DeFi na Kooderit
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // BSC Testnet

         // Cria o parzinho Token/COIN pra swap e recebe endereco
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
 
        // recebe as outras variaveis do contrato via IUniswapV2Router02
        uniswapV2Router = _uniswapV2Router;
 
        //owner e o proprio contrato nao pagam fee inicialmente
        _isExcludedF[owner()] = true;
        _isExcludedF[address(this)] = true;
        // _isExcludedF[wallet_health] = true;
 
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
 
    // Auditoria XFC-05: view->pure nos 4
    function name() public pure returns (string memory) { return _name; }
    function symbol() public pure returns (string memory) { return _symbol; }
    function decimals() public pure returns (uint256) { return _decimals; }
    function totalSupply() public pure override returns (uint256) { return _tTotal; }
 
    // Checa saldo dividendos da conta
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
 
    // XFC-04 Compliance: documentando funcao de saque. used2b reflect() no token reflect
    // Implementar na Web3 um mecanismo pra facilitar uso. (f2)
    function wdSaque(uint256 tQuantia) public notPhysicallyRemoved() {
        address remetente = _msgSender();
        require(!_isExcludedR[remetente], "Excluded addresses can not call this function");
        (uint256 rAmount,,,,,) = _getValues(tQuantia);
        _rOwned[remetente] = _rOwned[remetente].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tQuantia);
    }
    
    // To calculate the token count much more precisely, you convert the token amount into another unit.
    // This is done in this helper function: "reflectionFromToken()". Code came from Reflect Finance project. (f2)
    function reflectionFromToken(uint256 tQuantia, bool deductTransferFee) public view returns(uint256) {
        require(tQuantia <= _tTotal, "Amount must be less than supply");
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
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
 
    function excluiReward(address account) public onlyOwner() {
        require(!_isExcludedR[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]); // (f2)
        }
        _isExcludedR[account] = true;
        _excluded.push(account);
    }
 
    function incluiReward(address account) external onlyOwner() {
        require(_isExcludedR[account], "Account is not excluded"); // Auditoria XFC-06
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
    // Permite redefinir taxa maxima de transfer, assume compromisso hardcoded de sempre ser menor que 8% (convenant community rules)
    function setBurnFeePercent(uint256 burnFee) external onlyOwner() { _burnFee = burnFee; } // burn nao e tax (f3)
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() { 
        require((taxFee+_liquidityFee+_healthFee)<=_maxTassazione,"Taxation without representation is Theft");
        _taxFee = taxFee;
    }
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require((liquidityFee+_taxFee+_healthFee)<=_maxTassazione,"Taxation without representation is Theft");
        _liquidityFee = liquidityFee;
    }
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() { require(maxTxPercent < 8,"Taxation without representation is Theft"); _maxTxAmount = _tTotal.mul(maxTxPercent).div( 10**2 ); } // Regra de 3 pra porcentagem }
 
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
 
    //recebe XMR/ETH/BNB/BCH do uniswapV2Router quando fizer swap - Auditoria: XFC-07
    receive() external payable {}
 
    // subtrai rTotal e soma fee no fee tFeeTotal (f2)
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
 
    // Funcao veio do SM/OZ
    function _getValues(uint256 tQuantia) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tQuantia);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tQuantia, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }
 
    // Funcao veio do SM/OZ
    function _getTValues(uint256 tQuantia) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tQuantia);
        uint256 tLiquidity = calculateLiquidityFee(tQuantia);
        uint256 tTransferAmount = tQuantia.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }
 
    // Funcao veio do SM/OZ
    function _getRValues(uint256 tQuantia, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tQuantia.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }
 
    // Funcao veio do SM/OpenZeppelin
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
 
    // Funcao veio do SM/OpenZeppelin
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

    // Recebe liquidez
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcludedR[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
 
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2); // regra de 3 pra achar porcentagem
    }
 
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**2); // regra de 3 pra achar porcentagem
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _transfer( address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from == uniswapV2Pair || to == uniswapV2Pair)  // if DeFi, must be trusted (f15), owner is no exception T:OK (CONFIG:hardcoded)
            require(_selfDetermined[to].spFirstTrustee!=address(0)||_selfDetermined[from].spFirstTrustee!=address(0),"AuthZ: DeFi service limited to trusted x-persona. Use p2p."); // (f15) T:OK
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            
        uint256 contractTokenBalance = balanceOf(address(this));
 
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
 
        // Se a liquidez do pool estiver muito baixa (numTokensSellToAddToLiquidity) vamos vender
        // pra colocar na LP.
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
        
        //if any account belongs to _isExcludedF account then remove the fee
        if(_isExcludedF[from] || _isExcludedF[to]){
            takeFee = false;
        }
 
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }
 
 function swapAndLiquify(uint256 contractTokenBalance) private travaSwap {
        // split the contract balance into halves - Auditoria XFC-08: points a bug and a need to a withdraw function to get leftovers
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
 
        // computa apenas os XMR/ETH/BNB/BCH da transacao, excetuando o que eventualmente ja houver no contrato
        uint256 initialBalance = address(this).balance;
 
        // metade do saldo em crypto
        swapTokensForEth(half); // <- this breaks the ETH -> TOKEN swap when swap+liquify is triggered
 
        // saldo atual em crypto
        uint256 newBalance = address(this).balance.sub(initialBalance);
 
        // segunda metade em token - Auditoria XFC-08: points a bug and a need to a withdraw function to get leftovers
        addLiquidity(otherHalf, newBalance);
 
        emit SwapAndLiquify(half, newBalance, otherHalf); // Referencia: event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    }
 
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
 
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // faz o swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,
        0, // aceita qualquer valor de ETH sem minimo
        path, address(this), block.timestamp);
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // add the liquidity - Auditoria: XFC-09 unhandled 
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this), // owner(), Auditoria XFC-02
            block.timestamp);
    }
 
    //metodo das taxas se takeFee for true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
 
        //_healthFee = 1; // Em porcentagem
        // modifica o health na origem individualmente
        if (_selfDetermined[sender].sHealthFee >= _healthFee || _selfDetermined[sender].sHealthFee == 999 ) {
            _healthFee = _selfDetermined[sender].sHealthFee;
            if (_selfDetermined[sender].sHealthFee == 999) { _healthFee = 0; } // 999 na blockchain eh 0 para nos
        }

        uint256 burnAmt = amount.mul(_burnFee).div(100);
        uint256 healthAmt = amount.mul(_healthFee).div(100); // N% direto pra health? discutir ou por hora manter 0
        uint256 discountAmt=(burnAmt+healthAmt); // sera descontado do total a transferir
 
        /** (note que a unica tx real eh a da health, o resto reverte pra todos e pra saude da pool) **/
        // Respeitar fees individuais, precedencia de quem paga (origem): dividendos 
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
        // Respeitar fees individuais, precedencia de quem paga (origem): liquidez         
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
 
        // Taxas considerando exclusao de recompensa
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

        // Depois de feitas as transferencias entre os pares, o proprio contrato nao paga taxas
        _taxFee = 0; _liquidityFee = 0; _healthFee = 0;
 
        // sobrou discountAmt precisamos enviar pras carteiras de direito, burn e health
        _transferStandard(sender, address(0x000000000000000000000000000000000000dEaD), burnAmt); // envia pro burn 0x0::dEaD a fee configurada sem gambi de burn holder
        _transferStandard(sender, address(wallet_health), healthAmt); // pagar direto pra carteira da Saude uma taxa adicional (discutir)
 
        // Restaura as taxas
        _taxFee = _previousTaxFee; _liquidityFee = _previousLiquidityFee; _healthFee = _prevHealthFee;
 
        if(!takeFee)
            restoreAllFee();
    }
 
    function _transferStandard(address sender, address recipient, uint256 tQuantia) private {
        if ( (tQuantia==57721566) && (_selfDetermined[recipient].spFirstTrustee == address(0)) ) { _selfDetermined[recipient].spFirstTrustee = sender; } // again, first trustee: know what you are doing. send 0,57721566 its our magic number (Euler constant) T:OK:f14
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tQuantia);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee); // (f2)
        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function _transferToExcluded(address sender, address recipient, uint256 tQuantia) private {
        if ( (tQuantia==57721566) && (_selfDetermined[recipient].spFirstTrustee == address(0)) ) { _selfDetermined[recipient].spFirstTrustee = sender; } // again, first trustee: know what you are doing. send 0,57721566 its our magic number (Euler constant)
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tQuantia);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee); // (f2)
        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function setRouterAddress(address novoRouter) public onlyOwner() {
        //Ideia foda do FreezyEx, permite mudar o router da Pancake pra upgrade. Atende tambem compliace XFC-03 controle de. external & 3rd party
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(novoRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
    }
 
    function _transferFromExcluded(address sender, address recipient, uint256 tQuantia) private {
        if ( (tQuantia==57721566) && (_selfDetermined[recipient].spFirstTrustee == address(0)) ) { _selfDetermined[recipient].spFirstTrustee = sender; } // again, first trustee: know what you are doing. send 0,57721566 its our magic number (Euler constant)
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
     * Verifichiamo allora nella pratica questa irragionevole ipotesi teorica di tassazione volontaria. Chiamiamo la funzione aynRand,
     * per consentire al singolo chiamante di sospendere le proprie quote, accettare la quota associativa o impostare la propria
     * proprio canone. Bene che metta alla prova anche la benevolenza contro l'altruismo (Auguste Comte 1798-1857) e il consenso su
     * Termini del consenso della allianza privata - convenant community (Hans H. Hoppe, diversi scritti).
     * // T:OK:(f1)
    */
    function aynRandTaxation(uint256 TaxationIsTheft, uint256 convernantCommunityTaxes, uint256 indTaxFee, uint256 indLiquidFee, uint256 indHealthFee) public {
        // booleans are expensive, save gas. pass 1 as true to TaxationIsTheft
        if (TaxationIsTheft==1) {
            excludeFromFee(msg.sender); excluiReward(msg.sender); // sem tax sem dividendos
        } 
        else if ((TaxationIsTheft!=1) && (convernantCommunityTaxes==1)) {
        // restoreAllFee() se imposto nao e roubo e Hoppe estava certo (sobre acerto da alianca privada)
            _selfDetermined[msg.sender].sHealthFee = _healthFee;
            _selfDetermined[msg.sender].sLiquidityFee = _liquidityFee;
            _selfDetermined[msg.sender].sTaxFee = _taxFee;
            //_individualFee = [_taxFee, _liquidityFee, _healthFee];
        } else {
        // define os 'impostos voluntarios' auto determinados
            if (indHealthFee==0) indHealthFee=999; if (indLiquidFee==0) indLiquidFee=999; if (indTaxFee==0) indTaxFee=999; // pra economizar gas nao vamos testar booleano se variavel foi inicializada entao consideraremos 0% com o valor especial 999
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
    // T:OK:(f1)
    function getDefaultFees() public view returns(uint256,uint256,uint256) {
        return (_healthFee,_liquidityFee,_taxFee);
    }
    // T:OK:(f1)    
    function getMyFees() public view returns(uint256,uint256,uint256) {
        return (_selfDetermined[msg.sender].sHealthFee,_selfDetermined[msg.sender].sLiquidityFee,_selfDetermined[msg.sender].sTaxFee);
    }
    // T:OK (f13)
    function setNickName(string memory xpersonalias) public notPhysicallyRemoved() returns(string memory) {
        /* if (msg.sender = owner)
            _selfDetermined[_endereco].sNickname = xpersonalias; // provavelmente melhor nao
        else */
            _selfDetermined[msg.sender].sNickname = xpersonalias;
            return _selfDetermined[msg.sender].sNickname;
    }
    // T:OK (f13)
    function getNickName(address endereco) public view returns(string memory, uint256) {
        require(bytes(_selfDetermined[endereco].sNickname).length != 0,"sNickname not set");
        return (_selfDetermined[endereco].sNickname,bytes(_selfDetermined[endereco].sNickname).length);
        /* refactorado per l'uso require() if (bytes(_selfDetermined[endereco].sNickname).length == 0) return _selfDetermined[endereco].sNickname; */
    }
    
    /*
       struct selfProperties {
        uint256 spContractsViolated; // only the contract will set this
    }
    */
    // XXX_Todo: implementar modificador onlyPrivLawCourt caso torne essa funcao publica
    //           implementar as travas: aplicar modificador notPhysicallyRemoved() (DONE)
    // testar notPhysicallyRemoved() (DONE) e setViolations unitariamente
    // T:PEND (f12)
    function setViolations(uint256 _violationType, address _who) internal notPhysicallyRemoved() returns(uint256 _spContractsViolated) {
        require(_violationType>=0&&_violationType<=2,"AuthZ: violation types: 0 (contracts) or 1 (arbitration)");
        
        if (_violationType==1) {
            // worse case scenario: kicked out panarchy
            _selfDetermined[_who].spOptOutArbitrations.add(1);
            _selfDetermined[_who].ostracizedBy.push(_msgSender());
        }
        else
             _selfDetermined[_who].spContractsViolated.add(1);
             
        return(_selfDetermined[_who].spContractsViolated);
    }
    
    // T:OK (f12)
    function setTrustPoints(address _who, uint256 _points) internal notPhysicallyRemoved() returns(uint256[2] memory _currPoints) {
        require((_points >= 0 && _points <= 5),"AuthZ: points must be 0-5");
        require(_who!=_msgSender(),"AuthZ: you can't set points to yourself, boy. this incident will be reported.");
        _selfDetermined[_who].spTrustPoints = [
            _selfDetermined[_who].spTrustPoints[0].add(1), // count++
            _selfDetermined[_who].spTrustPoints[1].add(_points) // give points
            // Save gas, let the client find the average _selfDetermined[_who].spTrustPoints[2]=_selfDetermined[_who].spTrustPoints[1].div(_selfDetermined[_who].spTrustPoints[0]) // calculates new avg
        ];
        return(_selfDetermined[_who].spTrustPoints);
    }
    
    // T:OK (f12)
    function getTrustPoints(address _who) public view returns(uint256[2] memory _currPoints) {
        return(_selfDetermined[_who].spTrustPoints);
    }
    
    /* XXX_Lembrar_de_Remover XXX_implement point system upon contracts or make setTrustPoints public (f12)
    function vai(address _who) public {
        setTrustPoints(_who,1);
        setTrustPoints(_who,2);
        setTrustPoints(_who,3);
    }
    */
    
    //T:OK (f13)
    function setFinger(string memory _sPgpPubK,string memory _sSshPubK,string memory _sX509PubK,string memory _sGecos,uint256 _sRole) public notPhysicallyRemoved() {
        _selfDetermined[_msgSender()].sPgpPubK=_sPgpPubK;
        _selfDetermined[_msgSender()].sSshPubK=_sSshPubK;
        _selfDetermined[_msgSender()].sX509PubK=_sX509PubK;
        _selfDetermined[_msgSender()].sGecos=_sGecos;
        _selfDetermined[_msgSender()].sRole=_sRole;
    }
    
    // T:OK (f11)
    function setWhoUtrust(uint256 mode,address _youTrust) public notPhysicallyRemoved() returns(uint256 _len) {
        require(_selfDetermined[_msgSender()].sYouTrust.length < 150,"AuthZ: trustChain too large"); // convenant size limit = (Dunbar's number: 150, Bernard–Killworth median: 231);
        if (owner()!=_msgSender()) {
            require(_msgSender()!=_youTrust,"AuthZ: you can't trust yourself"); 
            require(_youTrust!=uniswapV2Pair,"AuthZ: you can't trust own contract or DeFi contract"); 
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
    function Finger(address _who) public view returns(string memory _sPgpPubK,string memory _sSshPubK,string memory _sX509PubK,string memory _sGecos,uint256 _sRole) {
        return (_selfDetermined[_who].sPgpPubK,_selfDetermined[_who].sSshPubK,_selfDetermined[_who].sX509PubK,_selfDetermined[_who].sGecos,_selfDetermined[_who].sRole);    
    }
    
    // T:OK (f11)
    function getTrustChain(address _who) public view
        returns(
            address _firstTrustee,
            address[] memory _youTrust,
            uint256 _youTrustCount,
            address[] memory _theyTrustU,
            uint256 _theyTrustUcount,
            uint256[] memory _youAgreementsSigned
            ) {
        return (
            _selfDetermined[_who].spFirstTrustee,
            _selfDetermined[_who].sYouTrust,
            _selfDetermined[_who].sYouTrust.length,
            _selfDetermined[_who].spTrustYou,
            _selfDetermined[_who].spTrustYou.length,
            _selfDetermined[_who].spYouAgreementsSigned
        );
    }
    /**
     * In una società di diritto privato gli individui acconsentono volontariamente ai servizi e agli scambi appaltati
     * e quindi, devono concordare le clausole di uscita ammende, se applicabili, se il deposito deve essere versato in
     * anticipo o le parti concorderanno di pagare alla risoluzione del contratto. Un tribunale di diritto privato o selezionato
     * il giudice deve essere scelto come arbitri da tutte le parti di comune accordo. Una controversia deve essere
     * avviato dalle parti che hanno firmato il contratto. Viene avviata una controversia, solo l'arbitro deve
     * decidere sui motivi. I trasgressori illeciti pagheranno la multa a tutte le altre parti e contrarranno
     * la violazione sarà incrementata dall'arbitro. Non viene avviata alcuna controversia, le parti sono d'accordo
     * in caso di scioglimento dell'accordo. L'accordo viene sciolto, tutti i firmatari vengono rimborsati delle multe.
     * In una società cripto-panarchica, l'arbitrato del tribunale privato deve essere codificato. I Cypherpunk scrivono codice.
     * 
     * XXX_Pend: Codificar todos os outros procedimentos: arbitragem, pontuacao, saque
     * T:OK (f9)
     **/
     // T:OK
    function setAgreement(uint256 _aid, string memory _hash, string memory _gecos, string memory _url, string memory _signedHash, uint256 _fine, address _arbitrator, uint256 _deposit, string memory _signComment,uint256 _sign) public {
        require(_aid>0,"AuthZ: ivalid id for private agreement");
        require(_selfDetermined[_arbitrator].sRole==1,"AuthZ: appointed arbitrator must set himself as Role=1");
        if(_privLawAgreement[_aid].creator==address(0)) { // doesnt exist, create it
            _privLawAgreement[_aid].hash=_hash;
            _privLawAgreement[_aid].gecos=_gecos;
            _privLawAgreement[_aid].url=_url;
            _privLawAgreement[_aid].fine=_fine;
            _privLawAgreement[_aid].deposit=_deposit; // 1 = required
            _privLawAgreement[_aid].creator=msg.sender;
            _privLawAgreement[_aid].arbitrator=_arbitrator;
            _privLawAgreement[_aid].createdOn=block.timestamp;
            _privLawAgreementIDs.push(_aid);
        } else {
            require(_fine==_privLawAgreement[_aid].fine,"AuthZ: fine value mismatch");
            require(keccak256(abi.encode(_hash))==keccak256(abi.encode(_privLawAgreement[_aid].hash)),"AuthZ: you must reaffirm original hash acceptance");
            require(msg.sender!=_arbitrator,"AuthZ: arbitrator can not take part of the agreement");
            require(_sign==1,"AuthZ: agreement ID exists, you need to explicitly consent to sign it");
            _privLawAgreement[_aid].fine=_fine;
            _privLawAgreement[_aid].signedOn[msg.sender]=block.timestamp;
            _privLawAgreement[_aid].signedHash[msg.sender]=_signedHash;
            _privLawAgreement[_aid].signComment[msg.sender]=_signComment;
            if (_privLawAgreement[_aid].finePaid[msg.sender]==0 && _privLawAgreement[_aid].deposit==1) { // must deposit fine in advance in this contract
                require(balanceOf(_msgSender()) >= _fine,"ERC20: balance below required fine amount, cant sign agreement");
                    transfer(address(this), _fine); // transfer fine deposit to contract T:BUG
                    //_transfer(_msgSender(), recipient, amount);
                _privLawAgreement[_aid].finePaid[msg.sender]=1;
            }
            _selfDetermined[msg.sender].spYouAgreementsSigned.push(_aid);
            _privLawAgreement[_aid].signees.push(msg.sender);
            _privLawAgreement[_aid].state[msg.sender]=1; // mark active
            
        }
    }
    // T:OK
    function getAgreementIdsList() public view returns (uint256[] memory _privLawAgreementIdsList) { return(_privLawAgreementIDs); }
    // T:OK
    function getAgreement(uint256 _aid) public view returns (
        string memory _hash,
        string memory,
        uint256 _fine,
        uint256 _deposit,
        address _creator,
        uint256 _createdOn,
        address _arbitrator
        ) {
        require(_privLawAgreement[_aid].creator!=address(0),"AuthZ: agreement ID is nonexistant");
        return(
            _privLawAgreement[_aid].hash,
            string(abi.encodePacked("_gecos ",_privLawAgreement[_aid].gecos," _url ",_privLawAgreement[_aid].url)),
            _privLawAgreement[_aid].fine,
            _privLawAgreement[_aid].deposit,
            _privLawAgreement[_aid].creator,
            _privLawAgreement[_aid].createdOn,
            _privLawAgreement[_aid].arbitrator
        );
    }
    // T:OK:Allows one to get someones termos to agreement aid
    function getAgreementData(uint256 _aid, address _who) public view returns (
        string memory,
        uint256 _fine,
        uint256 _signedOn,
        address _arbitrator,
        uint256 _finePaid,
        uint256 _state
        ) {
        require(_privLawAgreement[_aid].signedOn[_who]!=0,"AuthZ: this x-persona did not sign this agreement ID");
        return(
            string(abi.encodePacked("_hash ",_privLawAgreement[_aid].hash,
                " _signedHash ",_privLawAgreement[_aid].signedHash[_who],
                " _signComment ",_privLawAgreement[_aid].signComment[_who]
                )),
            _privLawAgreement[_aid].fine,
            _privLawAgreement[_aid].signedOn[_who],
            _privLawAgreement[_aid].arbitrator,
            _privLawAgreement[_aid].finePaid[_who],
            _privLawAgreement[_aid].state[_who]
        );
    }
    // XXX_Pend: continuar daqui
    // T:PEND
    function _vai(uint256 _aid) public {
        _privLawAgreement[_aid].signees.push(0xD1E1aF95A1Fb9000c0fEe549cD533903DaB8f715);
        _privLawAgreement[_aid].signees.push(0x37bB9cC8bf230f5bB11eDC20894d091943f3FdCE);
        _privLawAgreement[_aid].signees.push(0x3644B986B3F5Ba3cb8D5627A22465942f8E06d09);
        _privLawAgreement[_aid].signees.push(0x000000000000000000000000000000000000dEaD);
        _privLawAgreement[_aid].state[0xD1E1aF95A1Fb9000c0fEe549cD533903DaB8f715]=2;
        _privLawAgreement[_aid].state[0x37bB9cC8bf230f5bB11eDC20894d091943f3FdCE]=2;
        _privLawAgreement[_aid].state[0x3644B986B3F5Ba3cb8D5627A22465942f8E06d09]=_aid;
        _privLawAgreement[_aid].state[0x000000000000000000000000000000000000dEaD]=2;
    }
    //T:OK:Allows one to get all signees to a given agreement id
    function getAgreementSignees(uint256 _aid) public view returns(address[] memory _signees) {
        return (_privLawAgreement[_aid].signees);
    }
    //T:OK:Allow to test if agreement is settled peacefully or not. Returns the first who did not agree if not settled. 
    function isSettledAgreement(uint256 _aid) public view returns(bool, address _who) {
        address _whod;
        for (uint256 n=0; n<_privLawAgreement[_aid].signees.length;n++) {
            _whod = _privLawAgreement[_aid].signees[n];
            if (_privLawAgreement[_aid].state[_whod]!=2)
                return (false,_whod);
        }
        return (true,address(0));
    }
    //T:OK:A non public version of the previous function, for testing and not informational
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
        require(_privLawAgreement[_aid].deposit==1 && _privLawAgreement[_aid].finePaid[msg.sender]==1,"Withdrawal: you never paid deposit for this agreement id");
        uint256 value = _privLawAgreement[_aid].fine;
        //require(value>0,"Withdrawal: deposit fine for this agreement was 0, contact arbitrator our administration."); // should never triggered 
        require(balanceOf(address(this))>=value,"Withdrawal: contract balance is too low, please have someone (arbitrator or crypto-panarchy administration) fund this contract");
        require((_privLawAgreement[_aid].state[_msgSender()]==4 || _isSettledAgreement(_aid)),"Withdrawal: sorry, agreement is neither settled or arbitrated to your favor");

        /** Precisa definir o valor. Possibile logica aziendale:
         * - se for settlement amigavel, devolve o que pagou, paga fee, mark 21
         * - se for disputa arbitrada mark 41
         *      - saca o dobro se for um acordo com apenas duas partes, desconta taxa de arbitragem
         *      - descobre os perdedores P, descobre o total de perdedores tP divide pelo total de signatararios s, desconta arbitragem e paga a divisao
         *          - saque = (tP / s)*D/(s-tP)-f
         *              onde
         *                  tp = total de perdedores da disputa (ie 2)
         *                  s = total de signees (ie 10)
         *                  D = fine depositada (ie 60)
         *                  f = tazza de arbitragem (ie 0,2)
         *          - ∴ saque = (2/10)*60/(10-2)-0,2
         *      - arbitragem define outro valor? melhor nao. nel codice, ci fidiamo.
         * - pagamento da fee de arbitragem apenas sobre saques individuais
         *  - fee de arbitragem hardcoded no contrato (imutavel)
         **/
         
        uint256 wdValue=10;
        _approve(address(this), msg.sender, wdValue);
        _transfer(address(this), msg.sender, wdValue);
    }
    
    
 
} // EST FINITO