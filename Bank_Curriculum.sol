// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CurriculumDapp {
    address public owner;
    address public ufrnAuthority;
    address public ifrnAuthority;
    address public uernAuthority;
    address public mecAuthority;

    // Estrutura para armazenar informações sobre uma experiência profissional
    struct Experience {
        string title;
        string description;
        address verifyingAuthority;
        bool verified; 
        address superiorAuthority;
    }

    // Mapeamento de endereço para currículo (lista de experiências)
    mapping(address => Experience[]) public resumes;

    // Evento para notificar quando uma nova experiência é adicionada e precisa ser validada
    event ExperienceAdded(address indexed person, uint256 indexed index, string title, string description, address verifyingAuthority);

    // Modificador que garante que apenas o proprietário pode chamar uma função
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Construtor, define o proprietário como o criador do contrato e configura os endereços das entidades
    constructor(address _ufrnAuthority, address _ifrnAuthority, address _uernAuthority, address _mecAuthority) {
        owner = msg.sender;
        ufrnAuthority = _ufrnAuthority;
        ifrnAuthority = _ifrnAuthority;
        uernAuthority = _uernAuthority;
        mecAuthority = _mecAuthority;
    }

    
    function addExperience(string memory title, string memory description, address authority) external {
       
        require(msg.sender == owner, "Only the contract owner can add experiences");

        // Garante que a entidade validadora seja uma das entidades permitidas
        require(authority == ufrnAuthority || authority == ifrnAuthority || authority == uernAuthority || authority == mecAuthority, "Invalid verifying authority");

        // Adiciona a experiência ao currículo com o MEC como entidade superior por padrão
        Experience memory newExperience = Experience({
            title: title,
            description: description,
            verifyingAuthority: authority,
            verified: false,
            superiorAuthority: mecAuthority // Entidade superior é o MEC por padrão
        });

        resumes[msg.sender].push(newExperience);

        // Emite o evento para notificar a entidade verificadora
        emit ExperienceAdded(msg.sender, resumes[msg.sender].length - 1, title, description, authority);
    }

    // Função para solicitar verificação de uma experiência por parte da entidade superior
    function requestVerificationBySuperior(uint256 index, address superiorAuthority) external onlyOwner {
        // Apenas o dono do currículo pode solicitar verificação pela entidade superior
        require(msg.sender == owner, "Only the resume owner can request verification by superior authority");

        // Garante que o índice fornecido seja válido
        require(index < resumes[msg.sender].length, "Invalid index");

        // Atualiza a entidade superior para a experiência
        resumes[msg.sender][index].superiorAuthority = superiorAuthority;
    }

    // Função para que a entidade superior verifique e confirme uma experiência
    function verifyExperienceBySuperior(address person, uint256 index) external onlyOwner {
        // Garante que o índice fornecido seja válido
        require(index < resumes[person].length, "Invalid index");

        // Confirma a experiência pela entidade superior
        resumes[person][index].verified = true;
    }
 
   

    // Função auxiliar para comparar strings
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

// Função para buscar experiências com base em critérios específicos
function searchExperiences(address verifyingAuthority) external view returns (address[] memory, string[] memory, string[] memory, bool[] memory, address[] memory) {
    // Inicializa arrays para armazenar os resultados
    address[] memory users;
    string[] memory titles;
    string[] memory descriptions;
    bool[] memory verifiedStatus;
    address[] memory verifyingAuthorities;

    // Conta o número de experiências que atendem aos critérios
    uint256 count = 0;
    for (uint256 i = 0; i < resumes[msg.sender].length; i++) {
        Experience memory exp = resumes[msg.sender][i];
        bool matchesCriteria = (verifyingAuthority == address(0) || exp.verifyingAuthority == verifyingAuthority);

        if (matchesCriteria) {
            count++;
        }
    }

    // Aloca espaço nos arrays de resultados
    users = new address[](count);
    titles = new string[](count);
    descriptions = new string[](count);
    verifiedStatus = new bool[](count);
    verifyingAuthorities = new address[](count);

    // Preenche os arrays com os resultados
    uint256 index = 0;
    for (uint256 i = 0; i < resumes[msg.sender].length; i++) {
        Experience memory exp = resumes[msg.sender][i];
        bool matchesCriteria = (verifyingAuthority == address(0) || exp.verifyingAuthority == verifyingAuthority);

        if (matchesCriteria) {
            users[index] = msg.sender;
            titles[index] = exp.title;
            descriptions[index] = exp.description;
            verifiedStatus[index] = exp.verified;
            verifyingAuthorities[index] = exp.verifyingAuthority;
            index++;
        }
    }

    return (users, titles, descriptions, verifiedStatus, verifyingAuthorities);
    }
}