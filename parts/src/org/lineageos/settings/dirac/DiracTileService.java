package org.lineageos.settings.dirac;

import android.content.Context;
import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;

import org.lineageos.settings.R;

public class DiracTileService extends TileService {

    private DiracUtils mDiracUtils;
    private Context mContext;

    @Override
    public void onStartListening() {
        mContext = getApplicationContext();
        mDiracUtils = DiracUtils.getInstance(mContext);

        updateTileContent(mDiracUtils.isDiracEnabled());
        super.onStartListening();
    }

    @Override
    public void onClick() {
        boolean isEnabled = mDiracUtils.isDiracEnabled();
        mDiracUtils.setEnabled(!isEnabled);
        updateTileContent(!isEnabled);
        super.onClick();
    }

    private void updateTileContent(boolean isActive) {
        Tile tile = getQsTile();
        String on = mContext.getResources().getString(R.string.on);
        String off = mContext.getResources().getString(R.string.off);

        tile.setState(isActive ? Tile.STATE_ACTIVE : Tile.STATE_INACTIVE);
        tile.setContentDescription(isActive ? on : off);
        tile.setSubtitle(isActive ? on : off);
        tile.updateTile();
    }
}
