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
    SoloListing_two  =   {x = 1662.883, y = -25.811, z = 172.775,  name = _U('solo_listing'),   sprite = 315, color = 2},
    SoloListing_one  =   {x = 256.353, y = -1390.096, z = 29.555,  name = _U('solo_listing'),   sprite = 315, color = 2}
  },
  RegisterMulti =   {
    MultiListing_two  =   {x = 1662.727, y = -53.788, z = 167.329,  name = _U('multi_listing'),   sprite = 315, color = 1},
    MultiListing_one  =   {x = 216.088, y = -1389.518, z = 29.587,  name = _U('multi_listing'),   sprite = 315, color = 1}
  }
}

Config.AllowCopsToCollect = true
-- solo params
Config.RequiredCopsSolo = 0
Config.TimeToCollectSoloKey = 5 * 1000
-- multi params
Config.RequiredCopsMulti = 0
Config.TimeToCollectMultiKey = 5 * 1000
Config.MaxLaps = 24

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
  },
  {
    Name            =   'Little Lake Race',
    Label           =   'race',
    SoloRegister    =   'SoloListing_two',
    MultiRegister   =   'MultiListing_two',
    StartingBlock   =   {
      {x=1670.651,y=-33.005,z=172.774},
      {x=1671.117,y=-40.577,z=172.774},
      {x=1671.562,y=-48.390,z=172.774},
      {x=1673.265,y=-57.384,z=172.774},
    },
    Checkpoints     =   {
      {x=1669.83 , y=-26.422 , z=172.775},
      {x=1653.842, y=47.392  , z=171.418},
      {x=1829.884, y=174.312 , z=170.723},
      {x=1909.378, y=503.860 , z=170.668},
      {x=1988.511, y=955.508 , z=212.055},
      {x=1897.159, y=1309.823, z=151.001},
      {x=1578.417, y=961.265 , z=77.261 },
      {x=1701.498, y=1336.841, z=85.791 },
      {x=2179.104, y=1247.633, z=75.048 },
      {x=2271.261, y=1079.827, z=67.503 },
      {x=2432.844, y=585.725 , z=141.980},
      {x=2200.69 , y=117.609 , z=227.763},
      {x=1759.131, y=-92.326 , z=183.679},
      {x=1669.83 , y=-26.422 , z=172.775},
    }
  },
}