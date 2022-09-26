type options = {
    context : any
}

local function testDirectory(dir, options : options)
    local dirResults = {}
    
    for _, child in dir do
        if child:IsA("ModuleScript") then
            local module = require(child)

            dirResults[child.Name] = {}

            local currentTestCase = dirResults[child.Name]

            for caseName, caseFunction in module do
                local ok, err = pcall(caseFunction, options.context)

                currentTestCase[caseName] = {ok = ok, err = err}
            end

        elseif child:IsA("Folder") then
            dirResults[child.Name] = testDirectory(child:GetChildren(), options)
        end
    end

    return dirResults
end

local bootstrapper = {}

function bootstrapper:start(configuration : {directories : {}, options : options})
    local testResults = {}

    for _, directory : Folder in configuration.directories do
        testResults[directory.Name] = testDirectory(directory:GetChildren(), configuration.options)
    end 
end
return bootstrapper