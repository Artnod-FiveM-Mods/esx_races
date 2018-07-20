Locales['fr'] = {
  -- ********** SOLO **********
  -- Blips
  ['solo_key']            = 'Clé contre la montre',
  ['solo_listing']        = 'Liste des circuits',
  -- collect
	['press_collect_solo']  = 'Appuyez sur ~INPUT_CONTEXT~ pour récupérer\rune clé ~y~contre la montre~s~',
  ['inv_full_solo_key']   = 'Vous ne pouvez plus ramasser de clé\n~r~contre la montre~s~',
  -- register
	['press_solo_race_list']= 'Appuyez sur ~INPUT_CONTEXT~ pour accéder aux ~y~circuits~s~',
  ['register_ok']         = 'Inscription ~y~effectuée~s~\rAllez au point de ~r~départ~s~',
  ['already_register']    = 'Inscription ~r~déjà~s~ éffectuée\rAllez au point de ~r~départ~s~',
  ['no_solo_key']         = 'Vous n\'avez pas de clé ~r~contre-la-montre~s~',
  -- race
  ['ready_to_start']      = 'Atention au ~r~départ~s~',
  ['race_chrono']         = '~b~%s~s~\rTemps: ~y~%s~s~\rCheckpoint: ~y~%s/%s~s~',
  ['race_in_vehicle']     = 'Rentrez dans un ~r~VEHICULE~s~ !!\r~r~%s~s~',
  ['race_loose']          = 'Vous avez ~r~PERDU~s~ !!!',
  ['nice_ride']           = 'Bravo course terminé ~y~%s~s~',
  ['new_record']          = 'Nouveau record ~r~%s~s~',
	-- Menu
  ['own_stat']            = 'Stats personnel',
  ['daily_stat']          = 'Classement quotidien',
  ['monthly_stat']        = 'Classement mensuel',
  ['registration']        = 'Inscription',
  ['own_title']           = '%s - Perso',
  ['daily_title']         = '%s - Quotidien',
  ['monthly_title']       = '%s - Mensuel',
  ['record_notif']        = 'Temps: ~b~%s~s~\nParticipant: ~r~%s~s~\nle ~y~%s~s~ à ~y~%s~s~',
  -- ********** MULTI **********
  -- Blips
  ['multi_key']             = 'Clé course de rue',
  ['multi_listing']         = 'Liste des courses',
  -- collect
  ['press_collect_multi']   = 'Appuyez sur ~INPUT_CONTEXT~ pour récupérer\rune clé ~y~course de rue~s~',
  ['inv_full_multi_key']    = 'Vous ne pouvez plus ramasser de clé\n~r~course de rue~s~',
  -- ranking
  ['multi_record_notif']    = '~b~%s~s~ | ~b~%s~s~\nParticipant: ~r~%s~s~\nle ~y~%s~s~ à ~y~%s~s~',
  -- register
  ['press_multi_race_list'] = 'Appuyez sur ~INPUT_CONTEXT~ pour accéder aux ~y~courses~s~',
  ['no_race_ended']         = 'Pas de course terminées',
  ['no_multi_key']          = 'Vous n\'avez pas de clé ~r~course de rue~s~',
  ['multi_register_full']   = 'Impossible nombre de participant ~r~MAX~s~',
  ['multi_register_ok']     = 'Inscription ~y~effectuée~s~\rAttendez le ~r~départ~s~',
  -- edit
  ['race_already_exist']    = 'Une course de rue a ~r~déjà~s~ été créée',
  ['create_in_prog']        = '~y~Création~s~ effectuée',
  ['multi_change_fail']     = 'Valeur non valide',
  -- race
  ['multi_ready_to_start']  = 'Préparez vous au ~r~départ~s~',
  ['multi_wait_to_start']   = 'Attendez tous les participants.',
  ['multi_race_start']      = 'Atention au ~r~départ~s~',
  ['multi_race_chrono']     = '~b~%s~s~\rTemps: ~y~%s~s~\rTour: ~y~%s/%s~s~\rPos: ~y~%s/%s~s~',
  -- Menu home
  ['multi_home_title']      = 'Course de rue',
  ['ended_races']           = 'Classements',
  ['show_registration']     = 'Voir mon inscription',
  ['create_race']           = 'Créer une course de rue',
  ['edit_race']             = 'Modifier la course de rue',
  -- Menu ranking
  ['multi_rank_title']      = 'Classements',
  ['multi_rank_own']        = 'Classement Perso',
  ['multi_rank_race']       = '%s Tours - %s Pers - %s',
  ['multi_rank_own_race']   = '%s - %stours %spers - %s - %s',
  ['multi_rank_multi_title']= '%s - %s tours, %s pers',
  ['multi_rank_multi_race'] = '%s - %s - %s',
  -- Menu register
  ['multi_register_title']     = 'Sélectionner une course',
  ['multi_register_list']      = '%s: %s tours, %s pers',
  ['multi_my_register_title']  = 'Mon inscription',
  ['multi_register_registerC'] = 'Inscription fermée',
  ['multi_register_registerO'] = 'Inscription ouverte',
  ['multi_register_readyC']    = 'En attente du départ',
  ['multi_register_readyO']    = 'Prêt pour le départ',
  -- Menu edit
  ['multi_edit_title']      = 'Edition - %s',
  ['multi_edit_race']       = 'Circuit: %s',
  ['multi_edit_laps']       = 'Nombre de tours: %s',
  ['multi_edit_pers']       = 'Nombre de participants: %s',
  ['multi_edit_registerC']  = 'Fermer les inscriptions',
  ['multi_edit_registerO']  = 'Ouvrir les inscriptions',
  ['multi_edit_readyC']     = 'Arrêter la course',
  ['multi_edit_readyO']     = 'Démarrer la course',
  ['remove_multi']          = 'Annuler la course',
  -- Menu input
  ['multi_change_laps_title'] = 'Nombre de tours',
  ['multi_change_pers_title'] = 'Nombre de participants',
  ['multi_register_list']     = '%s: %s tours, %s pers',
  -- ********** COMMON **********
  ['pickup_in_prog']      = '~y~Ramassage~s~ en cours',
  ['pickup_retry']        = '~r~Attendre~s~ et Réessayez',
  ['out_vehicle']         = 'Vous devez sortir du ~r~véhicule~s~',
  ['act_imp_police']      = 'Action ~r~impossible~s~,\r~b~policiers~s~: ~r~%s/%s~s~',
  ['pickup_ok']           = 'Ramassage ~y~effectuée~s~',
  ['in_vehicle']          = 'Vous devez être dans un ~r~véhicule~s~',
  ['exit_marker']         = 'Appuyez sur ~INPUT_CONTEXT~ pour annuler le ~y~process~s~',
  ['no_race']             = 'Pas de ~r~circuits~s~',
  ['press_start_race']    = 'Appuyez sur ~INPUT_CONTEXT~ pour commencer la ~y~course~y~',
  ['no_record']           = 'Pas de ~r~temps~s~',
  ['remove_register']     = 'Annuler son inscription',
  ['removed_register']    = 'Inscription ~r~annulée~s~',
  ['value_between']       = 'La valeur doit être comprise\rentre ~r~%s et %s~s~',
}