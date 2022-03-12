"""renamed poi column to uid

Revision ID: 51eac9c9c842
Revises: e4dbb9cad692
Create Date: 2022-03-10 14:48:31.846895

"""
from alembic import op
import sqlalchemy as sa
import geoalchemy2
import sqlmodel  



# revision identifiers, used by Alembic.
revision = '51eac9c9c842'
down_revision = 'e4dbb9cad692'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('reached_poi_heatmap', sa.Column('accessibility_index', sa.Integer(), nullable=False), schema='customer')
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_column('reached_poi_heatmap', 'accessibility_index', schema='customer')
    # ### end Alembic commands ###
