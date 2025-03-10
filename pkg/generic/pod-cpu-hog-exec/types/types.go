package types

import (
	corev1 "k8s.io/api/core/v1"
	clientTypes "k8s.io/apimachinery/pkg/types"
)

// ExperimentDetails is for collecting all the experiment-related details
type ExperimentDetails struct {
	ExperimentName                string
	EngineName                    string
	ChaosDuration                 int
	ChaosInterval                 int
	RampTime                      int
	ChaosLib                      string
	AppNS                         string
	AppLabel                      string
	AppKind                       string
	ChaosUID                      clientTypes.UID
	InstanceID                    string
	ChaosNamespace                string
	ChaosPodName                  string
	CPUcores                      int
	PodsAffectedPerc              int
	Timeout                       int
	Delay                         int
	TargetPods                    string
	ChaosInjectCmd                string
	ChaosKillCmd                  string
	LIBImage                      string
	LIBImagePullPolicy            string
	StressImage                   string
	Annotations                   map[string]string
	TargetContainer               string
	Sequence                      string
	SocketPath                    string
	Resources                     corev1.ResourceRequirements
	ImagePullSecrets              []corev1.LocalObjectReference
	TerminationGracePeriodSeconds int
}
