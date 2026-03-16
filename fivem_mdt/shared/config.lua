Config = {}

Config.Core = 'qb-core'
Config.Command = 'mdt'

Config.Jobs = {
    Police = {
        names = { 'police', 'sheriff', 'statepolice' },
        minGrade = 0
    },
    EMS = {
        names = { 'ambulance', 'ems' },
        minGrade = 0
    },
    Dispatch = {
        names = { 'dispatch', 'police', 'sheriff' },
        minGrade = 2
    }
}

Config.Supervisor = {
    minPoliceGrade = 4
}

Config.MDTAuth = {
    enabled = true,
    sessionTimeoutMinutes = 120
}

Config.DispatchMap = {
    updateIntervalMs = 4000,
    worldBounds = { xMin = -4000.0, xMax = 4000.0, yMin = -4000.0, yMax = 8000.0 }
}

Config.Discord = {
    enabled = false,
    webhook911 = '',
    username = 'City Dispatch',
    avatar_url = ''
}

Config.PhoneBridge = {
    eventName = 'rs_mdt:server:phone911'
}

Config.AutoDispatch = {
    enabled = true,
    baseDelaySeconds = 20,
    minDelaySeconds = 8,
    maxDelaySeconds = 45,
    perDispatcherDelayBonus = 7,
    events = {
        shotsfired = { jobs = { 'police', 'sheriff', 'statepolice' }, priority = 1 },
        panic = { jobs = { 'police', 'sheriff', 'statepolice' }, priority = 1 },
        injury = { jobs = { 'ambulance', 'ems' }, priority = 2 },
        fire = { jobs = { 'ambulance', 'ems' }, priority = 2 },
        call911 = { jobs = { 'police', 'sheriff', 'statepolice', 'ambulance', 'ems' }, priority = 1 }
    }
}

Config.Permissions = {
    police = {
        canCreateWarrant = true,
        canCreateBOLO = true,
        canExpunge = false
    },
    ems = {
        canCreateMedicalRecord = true,
        canViewCriminalRecords = false
    }
}
