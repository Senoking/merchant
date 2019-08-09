tfm.exec.disableAutoNewGame(true)
tfm.exec.disableAutoShaman(true)
tfm.exec.disableAutoTimeLeft(true)

--game variables

local CONSTANTS = {
    BAR_WIDTH = 735,
    BAR_X = 60,
    STAT_BAR_Y = 30,

}

local celebrationEmotes = {
  tfm.enum.emote.dane, tfm.enum.emote.clap, tfm.enum.emote.confetti, tfm.enum.emote.partyhorn, tfm.enum.emote.carnaval
}

local players = {}
local healthPacks = {}
local courses = {}
local jobs = {}
local companies = {}
local tempData = {} --this table stores temporary data of players when they are creating a new job. Generally contains data in this order: tempPlayer = {jobName = 'MouseClick', jobSalary = 1000, jobEnergy = 0, minLvl = 100, qualification = "a pro"}

local closeButton = "<p align='right'><font color='#ff0000' size='13'><b><a href='event:close'>X</a></b></font></p>"
--creating the class Player

local Player = {}
Player.__index = Player
Player.__tostring = function(self)
    return "[name=" .. self.name .. ",money=" .. self.money .. ", health=" .. self.health .. "]"
end

setmetatable(Player, {
    __call = function (cls, name)
        return cls.new(name)
    end,
})

function Player.new(name)
    local self = setmetatable({}, Player)
    self.name = name
    self.money = 0
    self.health = 1.0
    self.healthBarId = 1000 + #players
    self.xpBarId = 2000 + #players
    self.healthRate = 0.002
    self.xp = 0
    self.level = 1
    self.learning = ""
    self.learnProgress = 0
    self.eduLvl = 1
    self.eduStream = ""
    self.degrees = {}
    self.job = "Cheese collector"
    self.ownedCompanies = {}
    self.boss = "shaman"
    ui.addTextArea(self.healthBarId, "", name, CONSTANTS.BAR_X, 340, CONSTANTS.BAR_WIDTH, 20, 0xff0000, 0xee0000, 1, true)
    ui.addTextArea(self.xpBarId, "", name, CONSTANTS.BAR_X, 370, 1, 17, 0x00ff00, 0x00ee00, 1, true)
    return self
end

function Player:getName() return self.name end
function Player:getMoney() return self.money end
function Player:getHealth() return self.health end
function Player:getHealthBarId() return self.healthBarId end
function Player:getHealthRate() return self.healthRate end
function Player:getXP() return self.xp end
function Player:getLevel() return self.level end
function Player:getLearningCourse() return self.learning end
function Player:getLearningProgress() return self.learnProgress end
function Player:getEducationLevel() return self.eduLvl end
function Player:getEducationStream() return self.eduStream end
function Player:getDegrees() return self.degrees end
function Player:getOwnedCompanies() return self.ownedCompanies end
function Player:getBoss() return self.boss end

function Player:work()
    if self.health -0.05 > 0 then
        local job = find(self.job, jobs)
        self.setHealth(self, -job.energy, true)
        self:setMoney(job.salary, true)
        self:setXP(1, true)
        players[job.owner]:setMoney(job.salary * 0.2)
        self:levelUp()
    end
end

function Player:setHealth(val, add)
    if add then
        self.health = self.health + val
    else
        self.health = val
    end
    self.health = self.health > 1  and 1 or self.health < 0 and 0 or self.health
    ui.addTextArea(self.healthBarId, "", self.name, CONSTANTS.BAR_X, 340, CONSTANTS.BAR_WIDTH * self.health, 20, 0xff0000, 0xee0000, 1, false)
    ui.updateTextArea(2, "<p align='center'>" .. math.ceil(self.health * 100) .. "%</p>", self.name)
end

function Player:setMoney(val, add)
    if add then
        self.money = self.money + val
    else
        self.money = val
    end
    self.money = self.money < 0 and 0 or self.money
    self:updateStatsBar()
end

function Player:setXP(val, add)
    if add then
        self.xp = self.xp + val
    else
        self.xp = val
    end
    ui.addTextArea(self.xpBarId, "", self.name, CONSTANTS.BAR_X, 370, ((self.xp - calculateXP(self.level)) / (calculateXP(self.level + 1) - calculateXP(self.level)))  * CONSTANTS.BAR_WIDTH, 17, 0x00ff00, 0x00ee00, 1, false)
    ui.updateTextArea(3, "<p align='center'>Level " .. self.level .. " - " ..self.xp .. "/" .. calculateXP(self.level + 1) .. "XP", self.name)
end

function Player:setCourse(course)
  self.learning = course.name
  self.learnProgress = 0
  self.eduLvl = course.level
  self.eduStream = course.stream
  ui.addTextArea(3000, "Lessons left: 0/" .. find(self.learning, courses).lessons, self.name, 5, 100, 50, 50, nil, nil, 0.8, false)
end

function Player:setJob(job)
  local jobRef = find(job, jobs)
  print(jobRef.minLvl < self.level)
  print(jobRef.qualifications == nil)
  print(table.indexOf(self.degrees, jobRef.qualifications))
  if jobRef.minLvl <= self.level and (jobRef.qualifications == nil or table.indexOf(self.degrees, jobRef.qualifications) ~= nil) then
    self.job = job
    self.boss = jobRef.owner
    print(self.job.salary)
  else print("No qualifications")
  end
end

function Player:addOwnedCompanies(comName)
  table.insert(self.ownedCompanies, comName)
end

function Player:addDegree(course)
  table.insert(self.degrees, course)
end

function Player:learn()
  if learning == "" then
    print("No course!")
  else
print(self.learning)
    if self.money > find(self.learning, courses).feePerLesson then
      self.learnProgress = self.learnProgress + 1
      ui.updateTextArea(3000, "Lessons left:" .. self.learnProgress .. "/" .. find(self.learning, courses).lessons, self.name)
      self:setMoney(-find(self.learning, courses).feePerLesson, true)
      if self.learnProgress >= find(self.learning, courses).lessons then
        self:addDegree(self.learning)
        print("Graduated")
        self.learning = ""
        self.eduLvl = self.eduLvl + 1
      end
    end
  end
end

function Player:levelUp()
    if self.xp >= calculateXP(self.level + 1) then
        self.level = self.level + 1
        self:setHealth(1.0, false)
        self:setMoney(5 * self.level, true)
        print("level up !" .. self.level .. " XP: " .. self.xp)
        displayParticles(self.name, tfm.enum.particle.star)
    end
end

function Player:useMed(med)
    if not (self.health >= 1) then
        self:setHealth(med.regainVal, med.adding)
        displayParticles(self.name, tfm.enum.particle.heart)
    end
end

function Player:updateStatsBar()
  ui.updateTextArea(1, self.name .. "<br>Money: $"  .. self.money .. " | Level " .. self.level, self.name)
end

--class creation(Player) ends

--class creation(Company)
local Company = {}
Company.__index = Company
Company.__tostring = function(self)
    return "[name=" .. self.name .. ",owner=" .. self.owner .. "]"
end

setmetatable(Company, {
    __call = function (cls, ...)
        return cls.new(...)
    end,
})

function Company.new(name, owner)
    local self = setmetatable({}, Company)
    self.name = name
    self.owner = owner
    self.members = {}
    self.jobs = {}
    self.uid = "com:" .. name
    return self
end

function Company:getName() return self.name end
function Company:getOwner() return self.owner end
function Company:getMembers() return self.members end
function Company:getJobs() return self.jobs end
function Company:getUID() return self.uid end

function Company:addMember(name)
  table.insert(self.members, name)
end

function Company:createJob()
  --table.insert(jobs, Job( ,self.name))
end

--class creation(Company) ends

--game functions

function displayShop(target)
    local medicTxt = ""
    for id, medic in ipairs(healthPacks) do
        medicTxt = medicTxt .. medic.name  .. " " .. medic.regainVal  .. " Price:" .. medic.price .. "<a href='event:" .. medic.uid .."'> Buy</a><br>"
    end
    ui.addTextArea(100, closeButton .. "<p align='center'><font size='20'><b><J>Shop</J></b></font></p><br></br>" .. medicTxt, target, 200, 90, 400, 200, nil, nil, 1, true)
end

function displayCourses(target)
  local courseTxt = ""
  local p = players[target]
  for id, course in ipairs(courses) do
    if p:getEducationLevel() == course.level and (p:getEducationStream() == course.stream or p:getEducationStream() == "") and learning ~= "" then
      courseTxt = courseTxt .. course.name .. " Fee: " .. course.fee .. " Lessons: " .. course.lessons .. " <a href='event:" .. course.uid .. "'>Enroll</a>'<br>"
    end
  end
  ui.addTextArea(200, closeButton .. "<p align='center'><font size='20'><b><J>Courses</J></b></font></p><br></br>" .. courseTxt, target, 200, 90, 400, 200, nil, nil, 1, true)
end

function displayJobs(target)
  local jobTxt = ""
  local p = players[target]
  for id, job in ipairs(jobs) do
  print(table.tostring(p:getDegrees()))
  print(job.qualifications)
    if p:getLevel() >= job.minLvl and (job.qualifications == nil or table.indexOf(p:getDegrees(), job.qualifications) ~= nil) then
      jobTxt = jobTxt .. job.name .. " Salary: " .. job.salary .. " Energy: " .. (job.energy * 100) .. "% <a href='event:" .. job.uid .. "'>Choose</a><br>"
    end
  end
  ui.addTextArea(300, closeButton .. "<p align='center'><font size='20'><b><J>Jobs</J></b></font></p><br><br>" .. jobTxt, target, 200, 90, 400, 200, nil, nil, 1, true)
end

function displayCompanyDialog(target)
  if #players[target]:getOwnedCompanies() == 0 then
    ui.addPopup(400, 1, "<p align='center'>No owned companies<br>Do you want to own one?</p>", target, 300, 90, 200, true)
  else
    local companyTxt = ""
    local p = players[target]
    for k, v in ipairs(p:getOwnedCompanies()) do
      local company = find(v, companies)
      companyTxt = companyTxt .. "<b><a href='event:" .. company:getUID() .. "'>" .. company:getName() .. "</a></b><br>Members: " .. (#company:getMembers() == 0 and "-" or string.sub(table.tostring(company:getMembers()), 2, -3))
    end
    ui.addTextArea(400, closeButton .. "<p align='center'><font size='20'><b><J>My Companies</J></b></font></p><br><br>" .. companyTxt, target, 200, 90, 400, 200, nil, nil, 1, true)
    ui.addTextArea(401, "<a href='event:createJob'>Create Job</a>", name, 500, 310, 100, 20, nil, nil, 1, true)

  end
end

function displayCompany(name, target)
  if find(name, companies) ~= nil then
    local com = find(name, companies)
    local companyTxt = ""
    local members = ""
    for k, v in ipairs(com:getMembers()) do
      members = members .. v .. "<br>"
    end
    ui.addTextArea(400, closeButton .. "<p align='center'><font size='20'><b><J>" .. name .. "</J></b></font></p><br><br><b>Owner</b>: " ..  com:getOwner() .. "<br><b>Members</b>: <br>" .. members, target, 200, 90, 400, 200, nil, nil, 1, true)   
  end
end

function displayJobWizard(target)
  ui.addTextArea(500, closeButton .. [[<p align='center'><font size='20'><b><J>Job Wizard</J></b></font></p><br><br>
    <b>Job Name: </b><a href='event:selectJobName'>Select</a>
    <b>Salary: </b><a href='event:selectJobSalary'>Select</a>
    <b>Enery: </b><a href='event:selectJobEnergy'>Select</a>
    <b>Minimum Level: </b><a href='event:chooseJobMinLvl'>Select</a>
    <b>Qualifcations: </b> Some degrees<br>
  ]], name, 200, 90, 400, 200, nil, nil, 1, true)
end

function calculateXP(lvl)
    return 2.5 * (lvl + 2) * (lvl - 1)
end

function displayParticles(target, particle)
  tfm.exec.displayParticle(particle, tfm.get.room.playerList[target].x, tfm.get.room.playerList[target].y, 0, -2, 0, 0, nil)
  tfm.exec.displayParticle(particle, tfm.get.room.playerList[target].x - 10, tfm.get.room.playerList[target].y, 0, -3, 0, 0, nil)
  tfm.exec.displayParticle(particle, tfm.get.room.playerList[target].x + 10, tfm.get.room.playerList[target].y, 0, -2, 0, 0, nil)
  tfm.exec.displayParticle(particle, tfm.get.room.playerList[target].x + math.random(-15, 15) , tfm.get.room.playerList[target].y, 0, -1, 0, 0, nil)
end

function find(name, tbl)
  for k,v in ipairs(tbl) do
    if (v.name == name) then
      return v
    end
  end
  return nil
end

--[[copied from the internet. lazy to write it by myself :D
  Credits: walterlua (https://gist.github.com/walterlua/978150/2742d9479cd5bfb3d08d90cfcb014da94021e271)
           jakbyte
]]
function table.indexOf(t, object)
    if type(t) ~= "table" then error("table expected, got " .. type(t), 2) end
    for i, v in pairs(t) do
        if object == v then
            return i
        end
    end
end

--[[copied from stackoverflow
  Credits: https://stackoverflow.com/users/1514861/ivo-beckers
  Question: https://stackoverflow.com/questions/1426954/split-string-in-lua
]]
function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function table.tostring(tbl)
  s = "["
  for k, v in pairs(tbl) do
    s = s .. k .. ":" .. v .. ", "
  end
  return s .. "]"
end

function HealthPack(_name, _price, _regainVal, _adding, _desc)
  return {
    name = _name,
    price = _price,
    regainVal = _regainVal,
    adding = _adding,
    uid = "health:" .. _name,
    desc = _desc
  }
end

function Course(_name, _fee, _lessons, _level, _stream)
  return {
    name = _name,
    fee = _fee,
    lessons = _lessons,
    level = _level,
    stream = _stream,
    feePerLesson = _fee / _lessons,
    uid = "course:" .. _name 
  }
end

function Job(_name, _salary, _energy, _minLvl, _qualifications, _owner)
  return {
    name = _name,
    salary = _salary,
    energy = _energy,
    minLvl = _minLvl,
    qualifications = _qualifications,
    owner = _owner,
    uid = "job:" .. _name
  }
end

function setUI(name)
    --textAreas
    --work
    ui.addTextArea(0, "<a href='event:work'><br><p align='center'><b>Work!</b></p>", name, 5, 340, 45, 50, 0x324650, 0x000000, 1, true)
    --stats
    ui.addTextArea(1, name .. "<br>Money : $0 | Level 1", name, 6, CONSTANTS.STAT_BAR_Y, 785, 40, 0x324650, 0x000000, 1, true)
    --health bar area
    ui.addTextArea(2, "<p align='center'>100%</p>", name, CONSTANTS.BAR_X, 340, CONSTANTS.BAR_WIDTH, 20, nil, nil, 0.5, false)
    --xp bar area
    ui.addTextArea(3, "<p align='center'>Level 1  -  0/" .. calculateXP(2) .. "XP</p>", name, CONSTANTS.BAR_X, 370, CONSTANTS.BAR_WIDTH, 20, nil, nil, 0.5, true)
    --shop button
    ui.addTextArea(4, "<a href='event:shop'>Shop</a>", name, 740, 300, 36, 20, nil, nil, 1, true)
    --school button
    ui.addTextArea(5, "<a href='event:courses'>Learn</a>", name, 740, 270, 36, 20, nil, nil, 1, true)
    --jobs button
    ui.addTextArea(6, "<a href='event:jobs'>Jobs</a>", name, 740, 240, 36, 20, nil, nil, 1, true)
    --Company button
    ui.addTextArea(7, "<a href='event:company'>Company</a>", name, 740, 210, 36, 20, nil, nil, 1, true)
end

--event handling

function eventNewPlayer(name)
    players[name] = Player(name)
    setUI(name)
end

function eventPlayerLeft(name)
    for n, player in ipairs(players) do
        if player:getName() == name then
            table.remove(players, n)
        end
    end
end
  
--function for the money clicker c:
function eventTextAreaCallback(id, name, evt)
    if evt == "work" then
        players[name]:work()
    elseif evt == "shop" then
        displayShop(name)
    elseif evt == "courses" then
        if players[name]:getLearningCourse() == "" then
          displayCourses(name)
        else 
          players[name]:learn()
        end
    elseif evt == "jobs" then
        displayJobs(name)
    elseif evt == "close" then
        ui.removeTextArea(id, name)
        if id == 400 then ui.removeTextArea(401, name) end
    elseif evt == "company" then
        displayCompanyDialog(name)
    elseif evt == "createJob" then
        displayJobWizard(name)
    elseif evt == "selectJobName" then
        ui.addPopup(601, 2, "<p align='center'>Please choose a name", name, 300, 90, 200, true)  
    elseif evt == "selectJobSalary" then
        ui.addPopup(602, 2, "<p align='center'>Please choose the salary (<i>Should be numbers!</i>)", name, 300, 90, 200, true)  
    elseif evt == "selectJobEnergy" then
        ui.addPopup(603, 2, "<p align='center'>Please select the energy (<i>Should be a number in range 0 - 100</i>)", name, 300, 90, 200, true)  
    elseif evt == "chooseJobMinLvl" then
        ui.addPopup(604, 2, "<p align='center'>Please select the minimum level (<i>Should be a number</i>", name, 300, 90, 200, true)  
    elseif evt:gmatch("%s+:%s+") then
        local type = split(evt, ":")[1]
        local val = split(evt, ":")[2]
        if type == "health" and players[name]:getMoney() - find(val, healthPacks).price >= 0 then
          local pack = find(val, healthPacks)
          players[name]:useMed(pack)
          players[name]:setMoney(-pack.price, true)
        elseif type == "course" then
          players[name]:setCourse(find(val, courses))
          ui.removeTextArea(id, name)
        elseif type == "job" then      
          players[name]:setJob(val)
          print(val)
        elseif type == "com" then
          displayCompany(val, name)
        end 
    end
end

function eventPopupAnswer(id, name, answer)
  print(id)
  print(answer)
  if id == 400 and answer == 'yes' then
    if players[name]:getMoney() < 10 then
      ui.addPopup(450, 0, "Not enough money!", name, 300, 90, 200, true)
    else 
      ui.addPopup(450, 2, "<p align='center'>Please choose a name<br>Price = 10<br>Click submit to buy!</p>", name, 300, 90, 200, true)
    end
  elseif id == 450 and answer ~= '' then
    table.insert(companies, Company(answer, name))
    players[name]:setMoney(-10, true)
    players[name]:addOwnedCompanies(answer)
    print(table.tostring(players[name]:getOwnedCompanies()))
  end
end

function eventLoop(t,r)
    for name, player in pairs(players) do
        player:setHealth(player:getHealthRate(), true)
    end
end

--event handling ends

--game logic

--creating and storing HealthPack tables
table.insert(healthPacks, HealthPack("Cheese", 5, 0.01, true,  "Just a cheese! to refresh yourself"))
table.insert(healthPacks, HealthPack("Cheese Pizza", 30, 0.05, true, "dsjfsdlkgjsdk"))
--creating and storing Course tables
table.insert(courses, Course("School", 20, 2, 1, ""))
table.insert(courses, Course("Junior mining", 10, 4, 1, ""))
table.insert(courses, Course("High School", 500, 20, 2, ""))
table.insert(courses, Course("Cheese mining", 1000, 30, 3, "admin"))
table.insert(courses, Course("Cheese trading", 2500, 30, 3, "bs"))
table.insert(courses, Course("Cheese developing", 2500, 50, 3, "it"))
table.insert(courses, Course("Cheese trading-II", 90000, 75, 4, "bs"))
table.insert(courses, Course("Fullstack cheese developing", 10000, 70, 4, "it"))
--creating and stofing Job tables
table.insert(jobs, Job("Cheese collector", 10, 0.05, 1, nil, "shaman"))
table.insert(jobs, Job("Junior miner", 25, 0.1, 3, nil, "shaman"))
table.insert(jobs, Job("Cheese producer", 50, 0.15, 7, nil))
table.insert(jobs, Job("Cheese miner", 250, 0.2, 10, "Cheese mining", "shaman"))
table.insert(jobs, Job("Cheese trader", 200, 0.2, 12, "Cheese trading", "shaman"))
table.insert(jobs, Job("Cheese developer", 300, 0.3, 12, "Cheese developing", "shaman"))
table.insert(jobs, Job("Cheese wholesaler", 700, 0.2, 15, "Cheese trading-II", "shaman"))
table.insert(jobs, Job("Fullstack cheeese developer", 1000, 0.4, 15, "Fullstack cheese developing", "shaman"))

players["shaman"] = Player("shaman")

for name, player in pairs(tfm.get.room.playerList) do
    players[name] = Player(name)
    setUI(name)
end
