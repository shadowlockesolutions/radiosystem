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
        fire = { jobs = { 'ambulance', 'ems' }, priority = 2 }
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
