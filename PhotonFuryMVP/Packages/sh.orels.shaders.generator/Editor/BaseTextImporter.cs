using System.IO;

using UnityEngine;

namespace ORL.ShaderGenerator
{
    public class BaseTextImporter : UnityEditor.AssetImporters.ScriptedImporter
    {
        public override void OnImportAsset(UnityEditor.AssetImporters.AssetImportContext ctx)
        {
            var textContent = File.ReadAllText(ctx.assetPath);
            var textAsset = new TextAsset(textContent);
            textAsset.name = "Content";
            ctx.AddObjectToAsset("Collection", textAsset);
            ctx.SetMainObject(textAsset);
        }
    }
}