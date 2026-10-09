#pragma once
#include "CoreMinimal.h"
#include "Serialization/JsonReader.h"
namespace FPSAssemblyJson
{
inline bool UniqueFields(const FString& Json)
{
    // FJsonObject collapses duplicate keys; reject them before materializing the object.
    auto Reader = TJsonReaderFactory<>::Create(Json);
    struct Frame { bool Object; TSet<FString> Keys; };
    TArray<Frame> Stack;
    EJsonNotation Token;
    while (Reader->ReadNext(Token))
    {
        if (Token == EJsonNotation::Error) return false;
        const bool End = Token == EJsonNotation::ObjectEnd || Token == EJsonNotation::ArrayEnd;
        if (!End && !Stack.IsEmpty() && Stack.Last().Object)
        {
            const FString Key = Reader->GetIdentifier();
            if (Stack.Last().Keys.Contains(Key)) return false;
            Stack.Last().Keys.Add(Key);
        }
        if (Token == EJsonNotation::ObjectStart || Token == EJsonNotation::ArrayStart)
        {
            if (Stack.Num() >= 32) return false;
            Frame F; F.Object = Token == EJsonNotation::ObjectStart; Stack.Add(MoveTemp(F));
        }
        else if (End)
        {
            if (Stack.IsEmpty()) return false;
            Stack.Pop();
        }
    }
    return Stack.IsEmpty() && Reader->GetErrorMessage().IsEmpty();
}
}
