pragma solidity ^0.4.18;

contract ServiceExchange{
    
    address private owner;
    
    function ServiceExchange() public{
        owner = msg.sender;
        serviceCount = 1;
        applicationsCount = 1;
    }
    
    struct Service{
        uint id;
        address employerAddress;
        string title;
        string image;
        string companyName;
        string description;
        uint compensation;
        bool isActive;
        bool approved;
        bool finished;
    }
    
    struct Applicant{
        uint id;
        address employeeAddress;
        bytes32 name;
        bytes32 contact;
        string cv;
        uint serviceId;
        address serviceAddress;
    }
    
    uint private serviceCount;
    uint private applicationsCount;
    
    mapping(uint => Service) private servicesByServiceId;
    mapping(uint => Applicant) private applicantByApplicantId;
    mapping(address => uint) private ballancePerAccount;
    mapping(uint => Applicant) private acceptedApplicationsByServiceId;
    

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    function getBalance() onlyOwner public view returns(uint){
        return this.balance;
    }
    
    function submitService(string title,string img,string company,string descr,uint comp) public{
        require(comp >= 0);
        Service memory service = Service({
            id:  serviceCount,
            employerAddress: msg.sender,
            title: title,
            image: img,
            companyName: company,
            description: descr,
            compensation: comp,
            isActive: true,
            approved: false,
            finished: false
        });
        if(msg.sender == owner){
            service.approved = true;
        }
        serviceCount++;
        servicesByServiceId[service.id] = service;
    }
    
    function approveServiceSubmission(uint id) onlyOwner public{
        servicesByServiceId[id].approved = true;
    }
    
    function getMyServicesAsEmployer() public view returns (uint[]){
        uint[] memory myApprovedServices = new uint[](serviceCount);
        uint index = 0;
        for (uint i=0; i<serviceCount; i++) {
            Service memory current = servicesByServiceId[i];
            if(current.employerAddress == msg.sender){
                myApprovedServices[index] = current.id;
                index++;
            }
        }
        return myApprovedServices;
    }
    
    function getMyApplicationsAsEmployee() public view returns (uint[]){
        uint[] memory myApplications = new uint[](applicationsCount);
        uint index = 0;
        for (uint i=0; i<applicationsCount; i++) {
            Applicant memory current = applicantByApplicantId[i];
            if(current.employeeAddress == msg.sender){
                myApplications[index] = current.id;
                index++;
            }
        }
        return myApplications;
    }
  
    function getMyApplicationsAsEmployer() public view returns (uint[]){
        uint[] memory myApplications = new uint[](applicationsCount);
        uint index = 0;
        for (uint i=0; i<applicationsCount; i++) {
            Applicant memory current = applicantByApplicantId[i];
            if(current.serviceAddress == msg.sender){
                myApplications[index] = current.id;
                index++;
            }
        }
        return myApplications;
    }
  
    function getAllApprovedServices() public view returns (uint[]){
        uint[] memory allApprovedServices = new uint[](serviceCount);
        uint index = 0;
        for (uint i=0; i<serviceCount; i++) {
            Service memory current = servicesByServiceId[i];
            if(current.approved == true){
                allApprovedServices[index] = current.id;
                index++;
            }
        }
        return allApprovedServices;
    }
    
     function getAllPendingServices() public onlyOwner view returns (uint[]){
        uint[] memory allPendingServices = new uint[](serviceCount);
        uint index = 0;
        for (uint i=0; i<serviceCount; i++) {
            Service memory current = servicesByServiceId[i];
            if(current.approved == false){
                allPendingServices[index] = current.id;
                index++;
            }
        }
        return allPendingServices;
    }
    
    function getApplicantById(uint id) public view returns(uint applicantId,
        address employeeAddress,
        bytes32 name,
        bytes32 contact,
        string cv,
        uint serviceId,
        address serviceAddress){
        Applicant memory applicant = applicantByApplicantId[id];
        require(msg.sender == applicant.employeeAddress || msg.sender == applicant.serviceAddress);
        
        return (applicant.id, applicant.employeeAddress, applicant.name, applicant.contact, applicant.cv, applicant.serviceId,applicant.serviceAddress);
    }
    
    function getServiceById(uint id) public view returns(uint serviceId,
        address employerAddress,
        string title,
        string image,
        string companyName,
        string description,
        uint compensation,
        bool isActive,
        bool approved,
        bool finished){
        
        Service memory service = servicesByServiceId[id];
        return (service.id, service.employerAddress, service.title, service.image,service.companyName, service.description, service.compensation,service.isActive,service.approved,service.finished);
    }
    
    
    function submitApplication(bytes32 name,bytes32 contacts,string cvFile,uint servId) public{
        Service memory service = servicesByServiceId[servId];
        require(msg.sender != service.employerAddress);
        Applicant memory applicant = Applicant({
            id: applicationsCount,
            employeeAddress: msg.sender,
            name: name,
            contact: contacts,
            cv: cvFile,
            serviceId: servId,
            serviceAddress: servicesByServiceId[servId].employerAddress
        });
        
        applicantByApplicantId[applicant.id] = applicant;
        applicationsCount++;
    }
    
    function confirmApplicationAndDeposit(uint applicantId) public payable{
        Applicant memory applicant = applicantByApplicantId[applicantId];
        require(applicant.serviceAddress == msg.sender);
        require(msg.value >= servicesByServiceId[applicant.serviceId].compensation);
        ballancePerAccount[msg.sender] += msg.value;
    }
    
    function markServiceAsComplete(uint applicantId) public{
        Applicant memory applicant = applicantByApplicantId[applicantId];
        Service memory service = servicesByServiceId[applicant.serviceId];
        require(applicant.serviceAddress == msg.sender);
        require(ballancePerAccount[msg.sender] >= service.compensation);
        applicant.employeeAddress.transfer(service.compensation);
        ballancePerAccount[msg.sender] -= service.compensation;
        servicesByServiceId[applicant.serviceId].finished = true;
    }
    
    function revokeService(uint serviceId) public{
        require(servicesByServiceId[serviceId].employerAddress == msg.sender);
        servicesByServiceId[serviceId].isActive = false;
    }
    
    function getBalanceForAccount() public view returns(uint){
        return ballancePerAccount[msg.sender];
    }
  
    function sendBalance(address addr) public onlyOwner {
        selfdestruct(addr);
    }
}