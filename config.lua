Config        = {}
Config.Locale = 'fr'

-- Markers
Config.ZonesData = {
  Enable = true,
  EnableBlip = true,
  Type = 1,
  DrawDistance = 100.0,
  Size     = {x = 2.0, y = 2.0, z = 2.0},
  Color  = {r = 100, g = 204, b = 100},
}
Config.StartZoneData = {
  Enable = true,
  Type = 1,
  DrawDistance = 250.0,
  Size     = {x = 2.0, y = 2.0, z = 2.0},
  Color  = {r = 200, g = 0, b = 0}  
}
Config.CheckpointsData = {
  Enable = true,
  EnableBlip = true,
  Type = 6,
  DrawDistance = 250.0,
  Size     = {x = 8.0, y = 8.0, z = 10.0},
  Color  = {r = 0, g = 200, b = 0},
  BlipColor = 69,
  OutTime = 15 * 1000
}
Config.Zones = {
  SoloKey       =   {x = 231.430, y = -1360.403, z = 27.651, name = _U('solo_key'),    sprite = 315, color = 2},
  MultiKey      =   {x = 199.859, y = -1382.469, z = 29.613, name = _U('multi_key'),    sprite = 315, color = 1},
  RegisterSolo  =   {
    SoloListing_one  =   {x = 256.353, y = -1390.096, z = 29.555,  name = _U('solo_listing'),   sprite = 315, color = 2}
  },
  RegisterMulti =   {
    MultiListing_one  =   {x = 216.088, y = -1389.518, z = 29.587,  name = _U('multi_listing'),   sprite = 315, color = 1}
  }
}

-- solo params
Config.RequiredCopsSolo = 0
Config.TimeToCollectSoloKey = 5 * 1000

-- multi params
Config.RequiredCopsMulti = 0
Config.TimeToCollectMultiKey = 5 * 1000

-- race
Config.Races = {
	{
    Name            =   'Licence Race',
    Label           =   'race',
		SoloRegister    =		'SoloListing_one',
    MultiRegister   =   'MultiListing_one',
    StartingBlock   =   {
      {x = 230.564, y = -1391.092, z = 29.500},
      {x = 229.257, y = -1393.385, z = 29.500},
      {x = 235.405, y = -1394.969, z = 29.500},
      {x = 224.416, y = -1389.508, z = 29.500},
      {x = 240.246, y = -1398.846, z = 29.500},
      {x = 229.257, y = -1393.385, z = 29.500},
    },
		Checkpoints     =		{
      {x = 255.139, y = -1400.731, z = 29.537},	
      {x = 271.874, y = -1370.574, z = 30.932},
      {x = 234.907, y = -1345.385, z = 29.542},
      {x = 217.821, y = -1410.520, z = 28.292},
      {x = 178.550, y = -1401.755, z = 27.725},
      {x = 113.160, y = -1365.276, z = 27.725},
      {x = -73.542, y = -1364.335, z = 27.789},
      {x = -355.143, y = -1420.282, z = 27.868},
      {x = -439.148, y = -1417.100, z = 27.704},
      {x = -453.790, y = -1444.726, z = 27.665},
      {x = -463.237, y = -1592.178, z = 37.519},
      {x = -900.647, y = -1986.28, z = 26.109},
      {x = 1225.759, y = -1948.792, z = 38.718},
      {x = 1225.759, y = -1948.792, z = 38.718},
      {x = 1163.603, y = -1841.771, z = 35.679},
      {x = 255.139, y = -1400.731, z = 29.537}
		}
	},
	{
    Name            =   'Simple Race',
    Label           =   'race',
    SoloRegister    =   'SoloListing_one',
    MultiRegister   =   'MultiListing_one',
    StartingBlock   =   {
      {x = 230.564, y = -1391.092, z = 29.500},
      {x = 229.257, y = -1393.385, z = 29.500},
      {x = 235.405, y = -1394.969, z = 29.500},
      {x = 224.416, y = -1389.508, z = 29.500},
      {x = 240.246, y = -1398.846, z = 29.500},
      {x = 229.257, y = -1393.385, z = 29.500},
    },
    Checkpoints     =   {
      {x = 255.139, y = -1400.731, z = 29.537}, 
      {x = 271.874, y = -1370.574, z = 30.932},
      {x = 234.907, y = -1345.385, z = 29.542},
      {x = 229.257, y = -1393.385, z = 29.500},
      {x = 255.139, y = -1400.731, z = 29.537}
    }
  }
}

Config.VehicleClass = {
  'compacts',
  'sedans',
  'SUV\'s',
  'coupes',
  'muscle',
  'sport classic',
  'sport',
  'super',
  'motorcycle',
  'offroad',
  'industrial',
  'utility',
  'vans',
  'bicycles',
  'boats',
  'helicopter',
  'plane',
  'service',
  'emergency',
  'military'
}