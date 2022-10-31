import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/bmi_calc.dart';

part 'profile_event.dart';

part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserUsecase getUserUsecase = GetUserUsecase();

  ProfileBloc() : super(ProfileInitial()) {
    on<LoadProfileEvent>((event, emit) async {
      emit(ProfileLoadingState());

      final user = await getUserUsecase.getUserData(event.context);
      final userBMIValue = BMICalc.getBMI(user);
      final userBMIEntity = UserBMIEntity(bmiValue: userBMIValue,
          nutritionalStatus: BMICalc.getNutritionalStatus(userBMIValue));

      emit(ProfileLoadedState(userBMI: userBMIEntity, userEntity: user));
    });
  }
}
