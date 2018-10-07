local robot = require('robot')
local c = require('component')
local nav = c.navigation
local geolyzer = c.geolyzer

local waypointsSearchingRange = 50

local requiredBlockNames = {
  "minecraft:log",
  "minecraft:leaves"
}

local function blockInList(foundBlockName)
  for i, blockName in ipairs(requiredBlockNames) do
    if foundBlockName == blockName then
      return true
    end
  end
  return false
end

local function breakAndTake(side)
  robot.swing(side)
  robot.suck()
end

local function analyzeAndBreakAndTake(side)
  local analyzeResult = geolyzer.analyze(side)
  if blockInList(analyzeResult['name']) then
    breakAndTake(side)
  else
    print('Этот блок нельзя ломать')
  end
end

local function standToNorth()
  local facing = nav.getFacing()
  if facing == 2 then
    robot.turnAround()
  elseif facing == 4 then
    robot.turnLeft()
  elseif facing == 5 then
    robot.turnRight()
  end
end

local function goToPoint(searchedPointName, enterPoint, ignoreY)
  local detectedWaypointsArray = nav.findWaypoints(waypointsSearchingRange)
  local isWaypointFound = false
  -- Перебор путевых точек для поиска той, к которой хотим придти
  for _, waypoint in pairs(detectedWaypointsArray) do
    if waypoint.label == searchedPointName then
      print('Путевая точка ' .. searchedPointName .. ' найдена') -------------
      isWaypointFound = true
      local waypointCoordinates = {
        waypointX = waypoint.position[1],
        waypointY = waypoint.position[2],
        waypointZ = waypoint.position[3]
      }
      local firstCoordinateChecked = false
      -- Движение робота по каждой из кооррдинат к путевой точке
      for positionCoordinateName, position in pairs(waypointCoordinates) do
        standToNorth()
        print('Встали к северу') ------
        if position ~= 0 and not (positionCoordinateName == "waypointY" and ignoreY) then
          --------------
          print('Параметры:')
          print('Имя координаты - waypointY? ' .. tostring(positionCoordinateName == "waypointY"))
          print('Действительное имя координаты: ' .. positionCoordinateName)
          print('Игрек игнорируется? ' .. tostring(ignoreY))
          print('Позиция равна нулю? ' .. tostring(position == 0))
          --------------
          local amountOfSteps = position
          local yIsPositive
          if positionCoordinateName == "waypointX" then
            print('Настройка в соответствии с координатой X') ------
            -- Если X-координата отрицательна
            if position < 0 then
              robot.turnRight()
              amountOfSteps = position * -1
            else
              robot.turnLeft()
            end
          elseif positionCoordinateName == "waypointZ" then
            print('Настройка в соответствии с координатой Z') ------
            if position < 0 then
              amountOfSteps = position * -1
              robot.turnAround()
            end
          elseif positionCoordinateName == "waypointY" then
            print('Настройка в соответствии с координатой Y') ------
            if position < 0 then
              yIsPositive = false
              amountOfSteps = position * -1
            else
              yIsPositive = true
            end
          end
          print('Кол-во необходимых для достижения цели шагов: ' .. amountOfSteps) ------
          for i = 1, amountOfSteps do
            if not enterPoint and i == amountOfSteps and firstCoordinateChecked then
              break
            end
            while true do
              local hasMoved, err
              if positionCoordinateName == "waypointY" then
                -- В случае, если текущая координата - Y, выбирается направление движения
                if yIsPositive then
                  hasMoved, err = robot.up()
                else
                  hasMoved, err = robot.down()
                end
              else
                hasMoved, err = robot.forward()
              end
              if hasMoved == nil then
                if err == 'entity' then
                  print('Kažkokia būtybė trukdo man judėti')
                elseif err == 'solid' then
                  print('Kažkoks daiktas trukdo man judėti')
                  -- Далее проверка блока на тип и принятие решения
                  --local analyzeResult
                  if positionCoordinateName == "waypointY" then
                    -- Если двигаемся вверх, то и блок обрабатываем верхний
                    if yIsPositive then
                      analyzeAndBreakAndTake(1)
                    -- В противном случае - нижний
                    else
                      analyzeAndBreakAndTake(0)
                    end
                  -- если движемся по горизонтали, то мы всегда смотрим по направлению движения
                  else
                    ---
                    analyzeAndBreakAndTake(3)
                  end
                end
              else
                break
              end
            end
          end
        end
        if positionCoordinateName ~= 'waypointY' then
          firstCoordinateChecked = true
        end
      end
      break
    end
  end
  if not isWaypointFound then
    print('The waypoint with such name haven\'t been found')
  end
end

goToPoint('chest', true, true)
goToPoint('back', true, true)

-- TODO: сделать detect перед движением в блок и исходя из этого принимать решение
-- На данный момент ошибка заключается в том, что тип координаты проверяется два раза

-- Поменять тип движения на диагональный ступенчатый
