import 'package:freezed_annotation/freezed_annotation.dart';
import 'density_grid.dart';

part 'density_request.freezed.dart';
part 'density_request.g.dart';

@freezed
sealed class DensityRequest with _$DensityRequest {
  const factory DensityRequest({
    required double lat,
    required double lng,
    @Default(5) int radiusMiles,
  }) = _DensityRequest;

  factory DensityRequest.fromJson(Map<String, dynamic> json) =>
      _$DensityRequestFromJson(json);
}

@freezed
sealed class DensityResponse with _$DensityResponse {
  const factory DensityResponse({
    required List<DensityGrid> grids,
    @Default(false) bool cached,
    int? executionTime,
  }) = _DensityResponse;

  factory DensityResponse.fromJson(Map<String, dynamic> json) =>
      _$DensityResponseFromJson(json);
}