#ifndef WATER_TESSELLATION_INCLUDED
#define WATER_TESSELLATION_INCLUDED

#ifdef TESSELLATION_VARIANT

TessellationControlPoint vertStandin (appdata v) {
	TessellationControlPoint p;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_OUTPUT(TessellationControlPoint, p);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(p);
	p.vertex = v.vertex;
	p.normal = v.normal;
	p.tangent = v.tangent;
	p.uv = v.uv;
	p.uv1 = v.uv1;
	return p;
}

struct TessellationFactors {
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

float TessellationEdgeFactor (TessellationControlPoint cp0, TessellationControlPoint cp1) {
	float3 vertex = (cp0.vertex.xyz + cp1.vertex.xyz) / 2;
	float3 p0 = mul(unity_ObjectToWorld, float4(vertex.xyz, 1)).xyz;
	float distanceVal = (distance(p0, _WorldSpaceCameraPos) - _TessDistMin) / (_TessDistMax - _TessDistMin);
	return pow(saturate(saturate(1-distanceVal)), 3);
}

TessellationFactors patchFunc (InputPatch<TessellationControlPoint, 3> patch) {
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[0]);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[1]);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[2]);
	TessellationFactors f;
    f.edge[0] = lerp(_TessMin, _TessMax, saturate(TessellationEdgeFactor(patch[1], patch[2])));
    f.edge[1] = lerp(_TessMin, _TessMax, saturate(TessellationEdgeFactor(patch[2], patch[0])));
    f.edge[2] = lerp(_TessMin, _TessMax, saturate(TessellationEdgeFactor(patch[0], patch[1])));
	f.inside = (f.edge[0] + f.edge[1] + f.edge[2]) * (1 / 3.0);
	return f;
}

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("fractional_odd")]
[UNITY_patchconstantfunc("patchFunc")]
TessellationControlPoint hullFunc (InputPatch<TessellationControlPoint, 3> patch, uint id : SV_OutputControlPointID) {
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[id]);
	return patch[id];
}

[UNITY_domain("tri")]
v2f domainFunc (TessellationFactors factors,OutputPatch<TessellationControlPoint, 3> patch,float3 barycentricCoordinates : SV_DomainLocation) {

	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[0]);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[1]);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[2]);

	TessellationControlPoint data;

	#define DOMAIN_PROGRAM_INTERPOLATE(fieldName) data.fieldName = \
		patch[0].fieldName * barycentricCoordinates.x + \
		patch[1].fieldName * barycentricCoordinates.y + \
		patch[2].fieldName * barycentricCoordinates.z;

	DOMAIN_PROGRAM_INTERPOLATE(vertex)
	DOMAIN_PROGRAM_INTERPOLATE(normal)
	DOMAIN_PROGRAM_INTERPOLATE(tangent)
	DOMAIN_PROGRAM_INTERPOLATE(uv)
	DOMAIN_PROGRAM_INTERPOLATE(uv1)
	DOMAIN_PROGRAM_INTERPOLATE(uv2)
	DOMAIN_PROGRAM_INTERPOLATE(uv3)
	
	UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(patch[0], data)

	return vert(data);
}

#endif // TESSELLATION_VARIANT
#endif // WATER_TESSELLATION_INCLUDED