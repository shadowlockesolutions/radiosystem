#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "RadioTypes.h"
#include "RadioComponent.generated.h"

class UAudioComponent;
class URadioSubsystem;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnStationChanged, FName, NewStationId);

UCLASS(ClassGroup = (Radio), meta = (BlueprintSpawnableComponent))
class RADIOSYSTEM_API URadioComponent : public UActorComponent
{
    GENERATED_BODY()

public:
    URadioComponent();

    virtual void BeginPlay() override;

    UFUNCTION(BlueprintCallable, Category = "Radio")
    void PowerOn(bool bEnable);

    UFUNCTION(BlueprintCallable, Category = "Radio")
    void NextStation();

    UFUNCTION(BlueprintCallable, Category = "Radio")
    void PreviousStation();

    UFUNCTION(BlueprintCallable, Category = "Radio")
    void SetMasterVolume(float NewVolume);

    UFUNCTION(BlueprintPure, Category = "Radio")
    bool IsOn() const { return bPoweredOn; }

    UPROPERTY(BlueprintAssignable, Category = "Radio")
    FOnStationChanged OnStationChanged;

private:
    UPROPERTY(EditAnywhere, Category = "Radio")
    TObjectPtr<USoundBase> TuningStaticSound;

    UPROPERTY(VisibleAnywhere, Category = "Radio")
    TObjectPtr<UAudioComponent> ProgramAudio;

    UPROPERTY(VisibleAnywhere, Category = "Radio")
    TObjectPtr<UAudioComponent> StaticAudio;

    UPROPERTY(ReplicatedUsing = OnRep_StationId)
    FName CurrentStationId;

    UPROPERTY(Replicated)
    bool bPoweredOn = true;

    UPROPERTY(Replicated)
    float MasterVolume = 1.0f;

    UFUNCTION()
    void OnRep_StationId();

    void Retune(bool bPlayStatic);
    void PlayResolvedStation();
    bool CanHearCurrentStation() const;

    UFUNCTION(Server, Reliable)
    void ServerSetStation(FName NewStationId);

    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;
};
