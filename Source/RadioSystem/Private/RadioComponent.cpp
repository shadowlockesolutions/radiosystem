#include "RadioComponent.h"

#include "Net/UnrealNetwork.h"
#include "Components/AudioComponent.h"
#include "Kismet/GameplayStatics.h"
#include "RadioSubsystem.h"

URadioComponent::URadioComponent()
{
    PrimaryComponentTick.bCanEverTick = false;
    SetIsReplicatedByDefault(true);

    ProgramAudio = CreateDefaultSubobject<UAudioComponent>(TEXT("ProgramAudio"));
    ProgramAudio->bAutoActivate = false;

    StaticAudio = CreateDefaultSubobject<UAudioComponent>(TEXT("StaticAudio"));
    StaticAudio->bAutoActivate = false;
}

void URadioComponent::BeginPlay()
{
    Super::BeginPlay();

    if (StaticAudio && TuningStaticSound)
    {
        StaticAudio->SetSound(TuningStaticSound);
    }

    if (CurrentStationId.IsNone())
    {
        CurrentStationId = TEXT("Music_Global");
    }

    Retune(false);
}

void URadioComponent::PowerOn(bool bEnable)
{
    bPoweredOn = bEnable;
    if (!bPoweredOn)
    {
        ProgramAudio->Stop();
        StaticAudio->Stop();
        return;
    }

    Retune(false);
}

void URadioComponent::NextStation()
{
    if (UGameInstance* GameInstance = GetWorld()->GetGameInstance())
    {
        if (URadioSubsystem* RadioSubsystem = GameInstance->GetSubsystem<URadioSubsystem>())
        {
            const TArray<FRadioStationDefinition>& Stations = RadioSubsystem->GetStations();
            if (Stations.IsEmpty())
            {
                return;
            }

            int32 CurrentIndex = Stations.IndexOfByPredicate([&](const FRadioStationDefinition& Station)
            {
                return Station.StationId == CurrentStationId;
            });

            CurrentIndex = (CurrentIndex + 1 + Stations.Num()) % Stations.Num();
            ServerSetStation(Stations[CurrentIndex].StationId);
        }
    }
}

void URadioComponent::PreviousStation()
{
    if (UGameInstance* GameInstance = GetWorld()->GetGameInstance())
    {
        if (URadioSubsystem* RadioSubsystem = GameInstance->GetSubsystem<URadioSubsystem>())
        {
            const TArray<FRadioStationDefinition>& Stations = RadioSubsystem->GetStations();
            if (Stations.IsEmpty())
            {
                return;
            }

            int32 CurrentIndex = Stations.IndexOfByPredicate([&](const FRadioStationDefinition& Station)
            {
                return Station.StationId == CurrentStationId;
            });

            CurrentIndex = (CurrentIndex - 1 + Stations.Num()) % Stations.Num();
            ServerSetStation(Stations[CurrentIndex].StationId);
        }
    }
}

void URadioComponent::SetMasterVolume(float NewVolume)
{
    MasterVolume = FMath::Clamp(NewVolume, 0.0f, 1.0f);
    ProgramAudio->SetVolumeMultiplier(MasterVolume);
}

void URadioComponent::OnRep_StationId()
{
    Retune(true);
}

void URadioComponent::Retune(bool bPlayStatic)
{
    if (!bPoweredOn)
    {
        return;
    }

    if (bPlayStatic && StaticAudio)
    {
        StaticAudio->Play();
    }

    PlayResolvedStation();
    OnStationChanged.Broadcast(CurrentStationId);
}

void URadioComponent::PlayResolvedStation()
{
    if (!CanHearCurrentStation())
    {
        ProgramAudio->Stop();
        return;
    }

    UWorld* World = GetWorld();
    UGameInstance* GameInstance = World ? World->GetGameInstance() : nullptr;
    URadioSubsystem* RadioSubsystem = GameInstance ? GameInstance->GetSubsystem<URadioSubsystem>() : nullptr;
    if (!RadioSubsystem)
    {
        return;
    }

    FRadioStationDefinition Station;
    if (!RadioSubsystem->ResolveStation(CurrentStationId, Station))
    {
        return;
    }

    const FRadioTrackSelection Selection = RadioSubsystem->ResolveCurrentTrack(CurrentStationId, GetWorld()->GetTimeSeconds());
    if (!Station.Tracks.IsValidIndex(Selection.TrackIndex))
    {
        return;
    }

    if (USoundBase* Sound = Station.Tracks[Selection.TrackIndex].Sound)
    {
        ProgramAudio->SetSound(Sound);
        ProgramAudio->SetVolumeMultiplier(Station.DefaultVolume * MasterVolume);
        ProgramAudio->Play(Selection.PlaybackStartSeconds);
    }
}

bool URadioComponent::CanHearCurrentStation() const
{
    if (const AActor* Owner = GetOwner())
    {
        if (const UWorld* World = GetWorld())
        {
            if (UGameInstance* GameInstance = World->GetGameInstance())
            {
                if (URadioSubsystem* RadioSubsystem = GameInstance->GetSubsystem<URadioSubsystem>())
                {
                    return RadioSubsystem->IsStationAudibleAtLocation(CurrentStationId, Owner->GetActorLocation());
                }
            }
        }
    }

    return false;
}

void URadioComponent::ServerSetStation_Implementation(FName NewStationId)
{
    CurrentStationId = NewStationId;
    Retune(true);
}

void URadioComponent::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);

    DOREPLIFETIME(URadioComponent, CurrentStationId);
    DOREPLIFETIME(URadioComponent, bPoweredOn);
    DOREPLIFETIME(URadioComponent, MasterVolume);
}
